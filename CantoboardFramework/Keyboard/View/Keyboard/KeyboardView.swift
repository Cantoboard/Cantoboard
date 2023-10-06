//
//  AlphabeticButtons.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/15/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift
import ISEmojiView

class KeyboardView: UIView, BaseKeyboardView {
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<KeyboardView>()
    
    weak var delegate: KeyboardViewDelegate?
    
    private var _state: KeyboardState
    var state: KeyboardState {
        get { _state }
        set { changeState(prevState: _state, newState: newValue) }
    }
    
    public var candidateOrganizer: CandidateOrganizer? {
        didSet {
            candidatePaneView?.candidateOrganizer = candidateOrganizer
        }
    }
    
    internal weak var statusMenu: StatusMenu?
    private weak var candidatePaneView: CandidatePaneView?
    private weak var emojiView: EmojiView?
    private var keyRows: [KeyRowView]!
    
    private var touchHandler: TouchHandler?
    // Touch event near the screen edge are delayed.
    // Overriding preferredScreenEdgesDeferringSystemGestures doesnt work in UIInputViewController,
    // As a workaround we use UILongPressGestureRecognizer to detect taps without delays.
    private weak var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    public var layoutConstants: Reference<LayoutConstants> = Reference(LayoutConstants.forMainScreen)
    private weak var newLineKey: KeyView?
    private weak var spaceKey: KeyView?
    private weak var loadingIndicatorView: UIActivityIndicatorView?
    
    private func createLoadingIndicatorView() {
        let loadingIndicatorView = UIActivityIndicatorView(style: .large)
        loadingIndicatorView.startAnimating()
        layoutLoadingIndicatorView()
        addSubview(loadingIndicatorView)
        
        self.loadingIndicatorView = loadingIndicatorView
    }
    
    init(state: KeyboardState) {
        self._state = state
        self.keyRows = []
        super.init(frame: .zero)
        
        backgroundColor = .clearInteractable
        insetsLayoutMarginsFromSafeArea = false
        isMultipleTouchEnabled = true
        preservesSuperviewLayoutMargins = false
        
        createsGestureRecognizer()
        createCandidatePaneView()
        
        setupView()
    }
    
    public override func didMoveToSuperview() {
        if superview == nil {
            touchHandler = nil
        } else {
            initTouchHandler()
        }
    }
    
    private func createsGestureRecognizer() {
        let longPressGestureRecognizer = BypassScreenEdgeTouchDelayGestureRecognizer(onTouchesBegan: { [weak self] touches, event in
            guard let self = self else { return }
            self.touchesBeganFromGestureRecoginzer(touches, with: event)
        })
        addGestureRecognizer(longPressGestureRecognizer)
        self.longPressGestureRecognizer = longPressGestureRecognizer
    }
    
    private func initTouchHandler() {
        touchHandler = TouchHandler(keyboardView: self, keyboardIdiom: state.keyboardIdiom)
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    private func changeState(prevState: KeyboardState, newState: KeyboardState) {
        var isViewDirty = prevState.keyboardType != newState.keyboardType ||
            prevState.keyboardContextualType != newState.keyboardContextualType ||
            prevState.symbolShape != newState.symbolShape ||
            prevState.activeSchema != newState.activeSchema ||
            prevState.inputMode != newState.inputMode || // In Cangjie family schemas, toggling inputMode changes the keyboard layout.
            prevState.keyboardIdiom != newState.keyboardIdiom ||
            prevState.lastKeyboardTypeChangeFromAutoCap != newState.lastKeyboardTypeChangeFromAutoCap ||
            prevState.isComposing != newState.isComposing ||
            prevState.isPortrait != newState.isPortrait ||
            prevState.specialSymbolShapeOverride != newState.specialSymbolShapeOverride ||
            prevState.isKeyboardAppearing != newState.isKeyboardAppearing ||
            prevState.charForm != newState.charForm
        
        if prevState.needsInputModeSwitchKey != newState.needsInputModeSwitchKey {
            keyRows.forEach { $0.needsInputModeSwitchKey = newState.needsInputModeSwitchKey }
            isViewDirty = true
        }
        
        if prevState.returnKeyType != newState.returnKeyType {
            newLineKey?.setKeyCap(.returnKey(newState.returnKeyType), keyboardState: state)
        }
        
        if prevState.spaceKeyMode != newState.spaceKeyMode {
            spaceKey?.setKeyCap(.space(newState.spaceKeyMode), keyboardState: state)
        }
        
        if prevState.enableState != newState.enableState {
            changeKeyboardEnabled(isEnabled: newState.enableState == .enabled, isLoading: newState.enableState == .loading)
        }
        
        if prevState.keyboardIdiom != newState.keyboardIdiom {
            touchHandler?.keyboardIdiom = newState.keyboardIdiom
        }
        
        touchHandler?.isComposing = newState.isComposing
        touchHandler?.hasForceTouchSupport = traitCollection.forceTouchCapability == .available
        
        _state = newState
        if isViewDirty { setupView() }
        
        candidatePaneView?.keyboardState = state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // DDLogInfo("layoutSubviews screen size \(UIScreen.main.bounds.size)")
        let layoutConstants = layoutConstants.ref
        layoutKeyboardSubviews(layoutConstants)
        layoutCandidateSubviews(layoutConstants)
        layoutLoadingIndicatorView()
        layoutStatusMenu()
    }
    
    func scrollCandidatePaneToNextPageInRowMode() {
        candidatePaneView?.scrollToNextPageInRowMode()
    }
    
    func setPreserveCandidateOffset() {
        candidatePaneView?.setPreserveCandidateOffset()
    }
    
    func changeCandidatePaneMode(_ mode: CandidatePaneView.Mode) {
        candidatePaneView?.changeMode(mode)
    }
    
    private func layoutKeyboardSubviews(_ layoutConstants: LayoutConstants) {
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: layoutConstants.keyboardViewInsets.top,
                                                           leading: layoutConstants.keyboardViewInsets.left,
                                                           bottom: layoutConstants.keyboardViewInsets.bottom,
                                                           trailing: layoutConstants.keyboardViewInsets.right)
        let keyRowsMargin: [NSDirectionalEdgeInsets] = (0..<keyRows.count).map {
            switch $0 {
            case 0: // First key row
                return NSDirectionalEdgeInsets(top: LayoutConstants.keyboardViewTopInset, leading: 0, bottom: layoutConstants.keyRowGapY / 2, trailing: 0)
            case keyRows.count - 1: // Last key row
                return NSDirectionalEdgeInsets(top: layoutConstants.keyRowGapY / 2, leading: 0, bottom: layoutConstants.keyboardViewInsets.bottom, trailing: 0)
            default: // Middle rows
                return NSDirectionalEdgeInsets(top: layoutConstants.keyRowGapY / 2, leading: 0, bottom: layoutConstants.keyRowGapY / 2, trailing: 0)
            }
        }
        
        let keyboardLayout = layoutConstants.idiom.keyboardViewLayout
        let keyRowsHeight: [CGFloat] = (0..<keyRows.count).map { keyRowsMargin[$0].top + keyboardLayout.getKeyHeight(atRow: $0, layoutConstants: layoutConstants) + keyRowsMargin[$0].bottom }
        
        var currentY: CGFloat = layoutConstants.autoCompleteBarHeight
        let keyRowsY: [CGFloat] = (0..<keyRows.count).map { (currentY, currentY += keyRowsHeight[$0]).0 }
        
        for (index, keyRowY) in keyRowsY.enumerated() {
            let keyRow = keyRows[index]
            keyRow.frame = CGRect(x: 0, y: keyRowY , width: frame.width, height: keyRowsHeight[index])
            keyRow.directionalLayoutMargins = keyRowsMargin[index]
        }
    }
    
    private func layoutCandidateSubviews(_ layoutConstants: LayoutConstants) {
        guard let candidatePaneView = candidatePaneView else { return }
        let height = candidatePaneView.mode == .row ? layoutConstants.autoCompleteBarHeight : bounds.height
        candidatePaneView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0,
                                                                             leading: layoutConstants.keyboardViewInsets.left,
                                                                             bottom: 0,
                                                                             trailing: layoutConstants.keyboardViewInsets.right)
        candidatePaneView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: bounds.width, height: height))
    }
    
    private func layoutLoadingIndicatorView() {
        let size: CGFloat = 20
        
        guard let loadingIndicatorView = loadingIndicatorView else { return }
        loadingIndicatorView.frame = CGRect(x: frame.midX - size / 2, y: frame.midY - size / 2, width: size, height: size)
    }
    
    private func refreshCandidatePaneViewVisibility() {
        if state.keyboardType == .emojis {
            destroyCandidatePaneView()
        } else {
            createCandidatePaneView()
        }
    }
    
    private func refreshKeyRowsVisibility() {
        if state.keyboardType == .emojis || candidatePaneView?.mode ?? .row == .table {
            keyRows.forEach { $0.isHidden = true }
        } else {
            keyRows.forEach { $0.isHidden = false }
        }
    }
    
    private func refreshKeys() {
        let layoutConstants = self.layoutConstants.ref
        
        let keyboardViewLayout = layoutConstants.idiom.keyboardViewLayout
        
        switch state.keyboardType {
        case let .alphabetic(shiftState):
            refreshAlphabeticKeys(keyboardViewLayout, shiftState)
        case .numeric, .numSymbolic:
            let rows = state.symbolShape == .full ? keyboardViewLayout.numbersFull : keyboardViewLayout.numbersHalf
            for (index, keyCaps) in rows.enumerated() {
                var keyCaps = configureNumberAndSymbolKeyCaps(keyCaps: keyCaps)
                configureLowerLeftSystemKeyCap(&keyCaps, rowId: index)
                keyRows[index].setupRow(keyboardState: state, keyCaps, rowId: index)
            }
        case .symbolic:
            let rows = state.symbolShape == .full ? keyboardViewLayout.symbolsFull : keyboardViewLayout.symbolsHalf
            for (index, keyCaps) in rows.enumerated() {
                var keyCaps = configureNumberAndSymbolKeyCaps(keyCaps: keyCaps)
                configureLowerLeftSystemKeyCap(&keyCaps, rowId: index)
                keyRows[index].setupRow(keyboardState: state, keyCaps, rowId: index)
            }
        default: ()
        }
        refreshSpaceAndReturnKeys()
    }
    
    private func refreshSpaceAndReturnKeys() {
        for row in keyRows {
            if let lastRowRightKeys = row.rightKeys,
               let newLineKey = lastRowRightKeys[safe: lastRowRightKeys.count - 1],
               case .returnKey = newLineKey.keyCap {
                self.newLineKey = newLineKey
                newLineKey.setKeyCap(.returnKey(state.returnKeyType), keyboardState: state)
            }
            
            if let lastRowMiddleKeys = row.middleKeys,
               let spaceKey = lastRowMiddleKeys[safe: 0],
               case .space = spaceKey.keyCap {
                self.spaceKey = spaceKey
                spaceKey.setKeyCap(.space(state.spaceKeyMode), keyboardState: state)
            }
        }
    }
    
    private func refreshAlphabeticKeys(_ layout: KeyboardViewLayout.Type, _ shiftState: (KeyboardShiftState)) {
        for (index, var keyCaps) in layout.letters.enumerated() {
            keyCaps = keyCaps.enumerated().map { groupId, keyCapGroup in
                keyCapGroup.compactMap {
                    return configureAlphabeticKeyCap($0, rowId: index, groupId: groupId, shiftState: shiftState)
                }
            }
            configureLowerLeftSystemKeyCap(&keyCaps, rowId: index)
            keyRows[index].setupRow(keyboardState: state, keyCaps, rowId: index)
        }
    }
        
    private func configureAlphabeticKeyCap(_ hardcodedKeyCap: KeyCap, rowId: Int, groupId: Int, shiftState: (KeyboardShiftState)) -> KeyCap? {
        let isInEnglishMode = state.inputMode == .english
        let isInCangjieMode = state.activeSchema.isCangjieFamily
        let isInMixedMode = state.inputMode == .mixed
        let isInLongPressMode = state.activeSchema.supportCantoneseTonalInput && Settings.cached.toneInputMode == .longPress
        let keyboardViewLayout = state.keyboardIdiom.keyboardViewLayout
        
        var keyCap: KeyCap
        if case .contextual(let contextualKey) = hardcodedKeyCap {
            guard let contextualTranslatedKey = keyboardViewLayout.getContextualKeys(key: contextualKey, keyboardState: state) else { return nil }
            return contextualTranslatedKey
        } else {
            keyCap = hardcodedKeyCap
        }
                
        switch keyCap {
        case .character(let c, let hints, var childrenKeyCaps):
            var leftHint = hints?.leftHint
            var rightHint = hints?.rightHint
            var bottomHint = hints?.bottomHint
            let isLetterKey = c.first?.isEnglishLetter ?? false
            let keyChar = shiftState != .lowercased && c.count == 1 ? c.uppercased() : c
            
            if shiftState != .lowercased && !state.lastKeyboardTypeChangeFromAutoCap && keyboardViewLayout.isSwipeDownKeyShiftMorphing(keyCap: keyCap),
               let swipeDownKeyCap = keyboardViewLayout.getSwipeDownKeyCap(keyCap: keyCap, keyboardState: state) {
                return swipeDownKeyCap
            }
            
            if state.showCommonSwipeDownKeysInLongPress {
                if let longPressKeyCap = CommonSwipeDownKeys.getSwipeDownKeyCapForPadShortOrFull4Rows(keyCap: keyCap, keyboardState: state) {
                    leftHint = longPressKeyCap.buttonText
                    let orgChildrenKeyCaps = KeyCap(keyChar).childrenKeyCaps.map { $0.withoutHints }
                    childrenKeyCaps = [longPressKeyCap] + orgChildrenKeyCaps
                }
            }
            // Special handling to make sure children keys don't go out of screen.
            // Move the parent key to the other side.
            if c == "e" || c == "i" || c == "o" || c == "u" {
                childrenKeyCaps = childrenKeyCaps ?? keyCap.childrenKeyCaps
                if let selfKeyCap = childrenKeyCaps?.remove(at: 1) {
                    childrenKeyCaps?.insert(selfKeyCap, at: 0)
                }
            }
            
            if isInCangjieMode && !isInEnglishMode && isLetterKey {
                let keyCapHints = KeyCapHints(leftHint: leftHint, rightHint: isInMixedMode ? c : rightHint, bottomHint: bottomHint)
                return .cangjie(keyChar, keyCapHints, childrenKeyCaps, Settings.cached.cangjieKeyCapMode)
            }
            
            if !isInEnglishMode && state.activeSchema.supportCantoneseTonalInput {
                if isInLongPressMode {
                    switch c {
                    case "r":
                        bottomHint = "aa"
                    case "v":
                        switch state.activeSchema {
                        case .jyutping: bottomHint = "oe/eo"
                        case .yale: bottomHint = "eu"
                        default: ()
                        }
                    case "x":
                        bottomHint = "ng"
                    default: ()
                    }
                }
                
                let orgChildren = childrenKeyCaps ?? keyCap.childrenKeyCaps
                if c == "r" {
                    rightHint = "反"
                    let cjSchema = Settings.cached.cangjieVersion.toRimeCJSchema
                    let quickSchema = Settings.cached.cangjieVersion.toRimeQuickSchema
                    childrenKeyCaps = [.reverseLookup(cjSchema), .reverseLookup(quickSchema)] + orgChildren + [.reverseLookup(.mandarin), .reverseLookup(.loengfan), .reverseLookup(.stroke)]
                } else if state.isComposing {
                    if isInLongPressMode {
                        var toneKeyCap: KeyCap? = nil
                        switch c {
                        case "f":
                            rightHint = "4"
                            toneKeyCap = KeyCap(rime: RimeChar.tone4)
                        case "g":
                            rightHint = "5"
                            toneKeyCap = KeyCap(rime: RimeChar.tone5)
                        case "h":
                            rightHint = "6"
                            toneKeyCap = KeyCap(rime: RimeChar.tone6)
                        case "c":
                            rightHint = "1"
                            toneKeyCap = KeyCap(rime: RimeChar.tone1)
                        case "v":
                            rightHint = "2"
                            toneKeyCap = KeyCap(rime: RimeChar.tone2)
                        case "b":
                            rightHint = "3"
                            toneKeyCap = KeyCap(rime: RimeChar.tone3)
                        default: ()
                        }
                        if let toneKeyCap = toneKeyCap {
                            childrenKeyCaps = orgChildren
                            childrenKeyCaps?.insert(toneKeyCap, at: 1)
                        }
                    } else {
                        switch c {
                        case "v": rightHint = "1/4"
                        case "x": rightHint = "2/5"
                        case "q": rightHint = "3/6"
                        default: ()
                        }
                    }
                }
            }
            
            let keyCapHints = leftHint == nil && rightHint == nil && bottomHint == nil ? nil : KeyCapHints(leftHint: leftHint, rightHint: rightHint, bottomHint: bottomHint)
            return .character(keyChar, keyCapHints, childrenKeyCaps)
        case .shift: return .shift(shiftState)
        case .keyboardType where groupId == 2 && state.keyboardIdiom.isPad:
            switch state.keyboardContextualType {
            case .rime: return CommonContextualKeys.getContextualKeys(key: .symbol, keyboardState: state)
            case .url: return CommonContextualKeys.getContextualKeys(key: .url, keyboardState: state)
            default: return keyCap
            }
        case .contextual: fatalError("Contextual isn't being translated properly. \(keyCap) \(state)")
        default: return keyCap
        }
    }
    
    private func configureNumberAndSymbolKeyCaps(keyCaps: [[KeyCap]]) -> [[KeyCap]] {
        return keyCaps.enumerated().map { groupId, keyCapGroup in
            keyCapGroup.compactMap { keyCap in
                return keyCap.symbolTransform(state: state)
            }
        }
    }
    
    private func configureLowerLeftSystemKeyCap(_ keyCaps: inout [[KeyCap]], rowId: Int) {
        if layoutConstants.ref.idiom.isPad && Settings.cached.padLeftSysKeyAsKeyboardType && keyCaps.count == 3 {
            if let keyboardTypeKeyCapIndex = keyCaps[0].firstIndex(where: { $0.isKeyboardType }) {
                // Move keyboard type key cap to the left corner.
                keyCaps[0].swapAt(keyboardTypeKeyCapIndex, 0)
            }
        }
        
        keyCaps[0] = keyCaps[0].compactMap { keyCap in
            switch keyCap {
            case .toggleInputMode:
                let showBottomLeftSwitchLangButton = Settings.cached.showBottomLeftSwitchLangButton || state.activeSchema.is10Keys
                if rowId == 3 && !showBottomLeftSwitchLangButton {
                    let shouldShowEmojiKey = layoutConstants.ref.idiom.isPad || state.needsInputModeSwitchKey
                    return shouldShowEmojiKey ? KeyCap.keyboardType(.emojis) : nil
                } else {
                    return .toggleInputMode(state.inputMode.afterToggle, state.activeSchema, true)
                }
            default: return keyCap
            }
        }
    }
    
    private func setupView() {
        createKeyRows()
        refreshCandidatePaneViewVisibility()
        candidatePaneView?.setupButtons()
        refreshKeyRowsVisibility()
        refreshKeys()
        refreshEmojiView()
    }
    
    private func createKeyRows() {
        let numOfKeyRows = layoutConstants.ref.idiom.keyboardViewLayout.numOfRows
        
        while keyRows.count < numOfKeyRows {
            let newKeyRow = KeyRowView(layoutConstants: layoutConstants)
            addSubview(newKeyRow)
            keyRows.append(newKeyRow)
        }
        
        while numOfKeyRows > keyRows.count {
            keyRows.removeLast().removeFromSuperview()
        }
    }
    
    private func refreshEmojiView() {
        if state.keyboardType == .emojis {
            createAndShowEmojiView()
        } else {
            destroyEmojiView()
        }
    }
    
    private func createCandidatePaneView() {
        guard candidatePaneView == nil else { return }
        
        let candidatePaneView = CandidatePaneView(keyboardState: state, layoutConstants: layoutConstants)
        candidatePaneView.candidateOrganizer = candidateOrganizer
        candidatePaneView.delegate = self        
        addSubview(candidatePaneView)        
        sendSubviewToBack(candidatePaneView)
        
        self.candidatePaneView = candidatePaneView
    }
    
    private func destroyCandidatePaneView() {
        guard let candidatePaneView = candidatePaneView else { return }
        candidatePaneView.removeFromSuperview()
        self.candidatePaneView = nil
    }
    
    private func createAndShowEmojiView() {
        guard self.emojiView == nil else { return }
        let keyboardSettings = KeyboardSettings(bottomType: .categories)
        keyboardSettings.needToShowAbcButton = true
        keyboardSettings.updateRecentEmojiImmediately = false
        keyboardSettings.isPhone = !layoutConstants.ref.idiom.isPad
        
        let emojiView = EmojiView(keyboardSettings: keyboardSettings)
        emojiView.delegate = self
        
        emojiView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emojiView)
        self.emojiView = emojiView
        
        NSLayoutConstraint.activate([
            emojiView.topAnchor.constraint(equalTo: self.topAnchor),
            emojiView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            emojiView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            emojiView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }
    
    private func destroyEmojiView() {
        guard let emojiView = emojiView else { return }
        emojiView.removeFromSuperview()
        self.emojiView = nil
    }
    
    private func changeKeyboardEnabled(isEnabled: Bool, isLoading: Bool = false) {
        keyRows.forEach { $0.isEnabled = isEnabled }
        if isLoading && loadingIndicatorView == nil {
            createLoadingIndicatorView()
            candidatePaneView?.isHidden = true
            touchHandler?.cancelAllTouches()
        } else if !isLoading {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil
            candidatePaneView?.isHidden = false
        }
    }
}

extension KeyboardView: CandidatePaneViewDelegate, StatusMenuHandler {
    func candidatePaneViewCandidateSelected(_ choice: IndexPath) {
        delegate?.handleKey(.selectCandidate(choice))
    }
    
    func candidatePaneViewExpanded() {
        setNeedsLayout()
        refreshCandidatePaneViewVisibility()
        refreshKeyRowsVisibility()
    }
    
    func candidatePaneViewCollapsed() {
        setNeedsLayout()
        refreshCandidatePaneViewVisibility()
        refreshKeyRowsVisibility()
    }
    
    func candidatePaneCandidateLoaded() {
        refreshCandidatePaneViewVisibility()
    }
    
    func handleKey(_ action: KeyboardAction) {
        delegate?.handleKey(action)
    }
    
    var statusMenuOriginY: CGFloat {
        layoutConstants.ref.autoCompleteBarHeight
    }
    
    var keyboardSize: CGSize {
        layoutConstants.ref.keyboardSize
    }
}

extension KeyboardView {
    // touchesBegan() is delayed if touches are near the screen edge.
    // We use GestureRecoginzer to workaround the delay.
    func touchesBeganFromGestureRecoginzer(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard statusMenu == nil else { return }
        for touch in touches {
            switch touch.view {
            case let key as KeyView:
                touchHandler?.touchBegan(touch, key: key, with: event)
            default: ()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard statusMenu == nil else { return }
        for touch in touches {
            let key = findTouchingView(touch, with: event) as? KeyView
            touchHandler?.touchMoved(touch, key: key, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard statusMenu == nil else { return }
        for touch in touches {
            let key = findTouchingView(touch, with: event) as? KeyView
            touchHandler?.touchEnded(touch, key: key, with: event)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        guard statusMenu == nil else { return }
        for touch in touches {
            touchHandler?.touchCancelled(touch, with: event)
        }
    }
    
    private func findTouchingView(_ touch: UITouch, with event: UIEvent?) -> UIView? {
        let touchPoint = touch.location(in: self)
        let touchingView = super.hitTest(touchPoint, with: event)
        return touchingView
    }
}

extension KeyboardView: EmojiViewDelegate {
    func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
        delegate?.handleKey(.emoji(emoji))
    }
    
    func emojiViewDidPressChangeKeyboardButton(_ emojiView: EmojiView) {
        delegate?.handleKey(.keyboardType(.alphabetic(.lowercased)))
    }
    
    func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView) {
        delegate?.handleKey(.backspace)
    }
}
