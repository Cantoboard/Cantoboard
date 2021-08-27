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
    
    private var candidateOrganizer: CandidateOrganizer
    
    internal weak var statusMenu: StatusMenu?
    private var candidatePaneView: CandidatePaneView?
    private var emojiView: EmojiView?
    private var keyRows: [KeyRowView]!
    
    private var touchHandler: TouchHandler!
    // Touch event near the screen edge are delayed.
    // Overriding preferredScreenEdgesDeferringSystemGestures doesnt work in UIInputViewController,
    // As a workaround we use UILongPressGestureRecognizer to detect taps without delays.
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    private weak var layoutConstants: Reference<LayoutConstants>?
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
    
    init(state: KeyboardState, candidateOrganizer: CandidateOrganizer, layoutConstants: Reference<LayoutConstants>) {
        self._state = state
        self.candidateOrganizer = candidateOrganizer
        self.layoutConstants = layoutConstants
        super.init(frame: .zero)
        
        backgroundColor = .clearInteractable
        insetsLayoutMarginsFromSafeArea = false
        isMultipleTouchEnabled = true
        preservesSuperviewLayoutMargins = false

        keyRows = (0..<4).map { i in KeyRowView(layoutConstants: layoutConstants) }
        switch layoutConstants.ref.idiom {
        case .phone, .padFloating:
            keyRows[0].rowLayoutMode = .phoneRowTop
            keyRows[3].rowLayoutMode = .phoneRowBottom
            keyRows.forEach { addSubview($0) }
        case .pad:
            keyRows.enumerated().forEach({ i, row in
                row.rowLayoutMode = .padRow(i)
                addSubview(row)
            })
        }
        
        initTouchHandler()
        createCandidatePaneView()
        
        setupView()
    }
    
    private func initTouchHandler() {
        longPressGestureRecognizer = UILongPressGestureRecognizer()
        longPressGestureRecognizer.minimumPressDuration = 0
        longPressGestureRecognizer.delegate = self
        addGestureRecognizer(longPressGestureRecognizer)
        
        touchHandler = TouchHandler(keyboardView: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    private func changeState(prevState: KeyboardState, newState: KeyboardState) {
        var isViewDirty = prevState.keyboardType != newState.keyboardType ||
            prevState.keyboardContextualType != newState.keyboardContextualType ||
            prevState.symbolShape != newState.symbolShape ||
            prevState.activeSchema != newState.activeSchema ||
            prevState.inputMode != newState.inputMode // In Cangjie family schemas, toggling inputMode changes the keyboard layout.
        
        if prevState.needsInputModeSwitchKey != newState.needsInputModeSwitchKey {
            keyRows.forEach { $0.needsInputModeSwitchKey = newState.needsInputModeSwitchKey }
            isViewDirty = true
        }
        
        if prevState.activeSchema != newState.activeSchema {
            isViewDirty = true
        }
        
        if prevState.returnKeyType != newState.returnKeyType {
            newLineKey?.setKeyCap(.returnKey(newState.returnKeyType))
        }
        
        if prevState.spaceKeyMode != newState.spaceKeyMode {
            spaceKey?.setKeyCap(.space(newState.spaceKeyMode))
        }
        
        if prevState.enableState != newState.enableState {
            changeKeyboardEnabled(isEnabled: newState.enableState == .enabled, isLoading: newState.enableState == .loading)
        }
        
        _state = newState
        if isViewDirty { setupView() }
        
        candidatePaneView?.keyboardState = state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // DDLogInfo("layoutSubviews screen size \(UIScreen.main.bounds.size)")
        guard let layoutConstants = self.layoutConstants?.ref else { return }
        
        layoutKeyboardSubviews(layoutConstants)
        layoutCandidateSubviews(layoutConstants)
        layoutLoadingIndicatorView()
        layoutStatusMenu()
    }
    
    func scrollCandidatePaneToNextPageInRowMode() {
        candidatePaneView?.scrollToNextPageInRowMode()
    }
    
    private func layoutKeyboardSubviews(_ layoutConstants: LayoutConstants) {
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: LayoutConstants.keyViewTopInset,
                                                           leading: layoutConstants.edgeHorizontalInset,
                                                           bottom: layoutConstants.keyViewBottomInset,
                                                           trailing: layoutConstants.edgeHorizontalInset)
        let keyRowsMargin: [NSDirectionalEdgeInsets] = (0..<keyRows.count).map {
            switch $0 {
            case 0: // First key row
                return NSDirectionalEdgeInsets(top: LayoutConstants.keyViewTopInset, leading: 0, bottom: layoutConstants.keyRowGap / 2, trailing: 0)
            case keyRows.count - 1: // Last key row
                return NSDirectionalEdgeInsets(top: layoutConstants.keyRowGap / 2, leading: 0, bottom: layoutConstants.keyViewBottomInset, trailing: 0)
            default: // Middle rows
                return NSDirectionalEdgeInsets(top: layoutConstants.keyRowGap / 2, leading: 0, bottom: layoutConstants.keyRowGap / 2, trailing: 0)
            }
        }
        
        let keyRowsHeight: [CGFloat] = keyRowsMargin.map { $0.top + layoutConstants.keyHeight + $0.bottom }
        
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
        guard let layoutConstants = self.layoutConstants?.ref else { return }
        
        let layout: KeyboardViewLayout.Type
        switch layoutConstants.idiom {
        case .phone, .padFloating:
            layout = PhoneKeyboardViewLayout.self
        case .pad:
            layout = PadKeyboardViewLayout.self
        }
        
        switch state.keyboardType {
        case let .alphabetic(shiftState):
            refreshAlphabeticKeys(layout, shiftState)
        case .numeric:
            let rows = state.symbolShape == .full ? layout.numbersFull : layout.numbersHalf
            for (index, var keyCaps) in rows.enumerated() {
                keyCaps = keyCaps.map { $0.map {
                    switch $0 {
                    case .currency:
                        return .character(SessionState.main.currencySymbol)
                    default:
                        return $0
                    }
                } }
                keyRows[index].setupRow(keyboardType: state.keyboardType, keyCaps)
            }
        case .symbolic:
            let rows = state.symbolShape == .full ? layout.symbolsFull : layout.symbolsHalf
            for (index, keyCaps) in rows.enumerated() {
                keyRows[index].setupRow(keyboardType: state.keyboardType, keyCaps)
            }
        default:
            ()
        }
    }
    
    private func refreshAlphabeticKeys(_ layout: KeyboardViewLayout.Type, _ shiftState: (KeyboardShiftState)) {
        for (index, var keyCaps) in layout.letters.enumerated() {
            if shiftState != .lowercased {
                keyCaps = keyCaps.map { $0.map {
                    switch $0 {
                    case .character(let c):
                        return .character(c.uppercased())
                    case .shift:
                        return .shift(shiftState)
                    default:
                        return $0
                    }
                } }
            }
            
            let isInEnglishMode = state.inputMode == .english
            // let rimeSchema = state.rimeSchema
            keyCaps = keyCaps.map { $0.map {
                switch $0 {
                case .character(let c) where state.activeSchema.isCangjieFamily && c.first?.isEnglishLetter ?? false && !isInEnglishMode:
                    return state.inputMode == .mixed ? .cangjieMixedMode(c) : .cangjie(c)
                case .character("F"), .character("G"), .character("H"),
                     .character("C"), .character("V"), .character("B"),
                     .character("f"), .character("g"), .character("h"),
                     .character("c"), .character("v"), .character("b"):
                    switch state.keyboardContextualType {
                    case .rime, .url(true):
                        if case .character(let c) = $0,
                           !isInEnglishMode &&
                            (state.activeSchema == .jyutping && Settings.cached.toneInputMode == .longPress || state.activeSchema == .yale) {
                            // Show tone keys.
                            return .characterWithConditioanlPopup(c)
                        } else {
                            return $0
                        }
                    default:
                        return $0
                    }
                case "R", "r":
                    if !isInEnglishMode && state.activeSchema.isCantonese, case .character(let c) = $0 {
                        return .characterWithConditioanlPopup(c)
                    }
                    return $0
                case .contextualSymbols:
                    return .contextualSymbols(isInEnglishMode ? .english : state.keyboardContextualType)
                case .returnKey: return .returnKey(state.returnKeyType)
                case .space: return .space(state.spaceKeyMode)
                default: return $0
                }
            } }
            
            keyRows[index].setupRow(keyboardType: state.keyboardType, keyCaps)
        }
        if let lastRow = keyRows[safe: 3] {
            if let lastRowRightKeys = lastRow.rightKeys {
                newLineKey = lastRowRightKeys[safe: lastRowRightKeys.count - 1]
            }
            if let lastRowMiddleKeys = lastRow.middleKeys {
                spaceKey = lastRowMiddleKeys[safe: 0]
            }
        }
    }
    
    private func setupView() {
        refreshCandidatePaneViewVisibility()
        candidatePaneView?.setupButtons()
        refreshKeyRowsVisibility()
        refreshKeys()
        refreshEmojiView()
    }
    
    private func refreshEmojiView() {
        if state.keyboardType == .emojis {
            createAndShowEmojiView()
        } else {
            destroyEmojiView()
        }
    }
    
    private func createCandidatePaneView() {
        guard candidatePaneView == nil, let layoutConstants = layoutConstants else { return }
        
        let candidatePaneView = CandidatePaneView(keyboardState: state, candidateOrganizer: candidateOrganizer, layoutConstants: layoutConstants)
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
        layoutConstants?.ref.autoCompleteBarHeight ?? .zero
    }
    
    var keyboardSize: CGSize {
        layoutConstants?.ref.keyboardSize ?? .zero
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
                touchHandler.touchBegan(touch, key: key, with: event)
            default: ()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard statusMenu == nil else { return }
        for touch in touches {
            let key = findTouchingView(touch, with: event) as? KeyView
            touchHandler.touchMoved(touch, key: key, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard statusMenu == nil else { return }
        for touch in touches {
            let key = findTouchingView(touch, with: event) as? KeyView
            touchHandler.touchEnded(touch, key: key, with: event)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        guard statusMenu == nil else { return }
        for touch in touches {
            touchHandler.touchCancelled(touch, with: event)
        }
    }
    
    private func findTouchingView(_ touch: UITouch, with event: UIEvent?) -> UIView? {
        let touchPoint = touch.location(in: self)
        let touchingView = super.hitTest(touchPoint, with: event)
        return touchingView
    }
}

extension KeyboardView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        let beganTouches = event.allTouches?.filter { $0.phase == .began }
        if let beganTouches = beganTouches, beganTouches.count > 0 {
            touchesBeganFromGestureRecoginzer(Set(beganTouches), with: event)
        }
        return false
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