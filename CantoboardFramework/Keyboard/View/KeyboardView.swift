
//
//  AlphabeticButtons.swift
//  Stockboard
//
//  Created by Alex Man on 1/15/21.
//

import Foundation
import UIKit

import ISEmojiView

protocol KeyboardViewDelegate: NSObject {
    func handleKey(_ action: KeyboardAction)
    func handleInputModeList(from: UIView, with: UIEvent)
    func onCandidateSelected(_ candidateIndex: Int)
}

class KeyboardView: UIView {
    private var _keyboardType = KeyboardType.alphabetic(.lowercased)
    private var _keyboardContextualType: ContextualType = .english
    private var _needsInputModeSwitchKey = false
    
    private var candidatePaneView: CandidatePaneView?
    private var emojiView: EmojiView?
    private var keyRows: [KeyRowView]!
    private var touchHandler: TouchHandler!
    private var _isEnabled = true
    weak var delegate: KeyboardViewDelegate?
    
    private let englishLettersKeyCapRows: [[[KeyCap]]] = [
        [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]],
        [["a", "s", "d", "f", "g", "h", "j", "k", "l"]],
        [[.shift(.lowercased)], ["z", "x", "c", "v", "b", "n", "m"], [.backspace]],
        [[.keyboardType(.numeric), .nextKeyboard], [.space], [.contexualSymbols(.english), .newLine]]
    ]
    
    private let numbersKeyCapRows: [[[KeyCap]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]],
        [["-", "/", ":", ";", "(", ")", "$", "\"", "「", "」"]],
        [[.keyboardType(.symbolic)], [".", ",", "、", "&", "?", "!", "‘"], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space], ["@", .newLine]]
    ]
    
    private let symbolsKeyCapRows: [[[KeyCap]]] = [
        [["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]],
        [["_", "—", "\\", "|", "~", "<", ">", "《", "》", "•"]],
        [[.keyboardType(.numeric)], ["。", "，", "、", "^_^", "？", "！", "‘"], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space], [.newLine]]
    ]
    
    var keyboardType: KeyboardType {
        get { _keyboardType }
        set {
            if _keyboardType != newValue {
                _keyboardType = newValue
                setupView()
            }
        }
    }
    
    var keyboardContextualType: ContextualType {
        get { _keyboardContextualType }
        set {
            if _keyboardContextualType != newValue {
                _keyboardContextualType = newValue
                setupView()
            }
        }
    }
    
    var needsInputModeSwitchKey: Bool {
        get { _needsInputModeSwitchKey }
        set {
            if _needsInputModeSwitchKey != newValue {
                _needsInputModeSwitchKey = newValue
                setupView()
            }
        }
    }
    
    var candidateSource: CandidateSource? {
        get { candidatePaneView?.candidateSource }
        set {
            candidatePaneView?.candidateSource = newValue
        }
    }
        
    var isEnabled: Bool {
        get { _isEnabled }
        set {
            if _isEnabled != newValue {
                keyRows.forEach { $0.isEnabled = newValue }
            }
            _isEnabled = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clearInteractable
        insetsLayoutMarginsFromSafeArea = false
        isMultipleTouchEnabled = true
        preservesSuperviewLayoutMargins = false

        keyRows = (0..<4).map { i in KeyRowView() }
        keyRows[0].rowLayoutMode = .topRow
        keyRows[2].rowLayoutMode = .shiftRow
        keyRows[3].rowLayoutMode = .bottomRow
        keyRows.forEach { addSubview($0) }
                
        initTouchHandler()
        createCandidatePaneView()
        
        setupView()
    }
    
    private func initTouchHandler() {
        touchHandler = TouchHandler(keyboardView: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layoutConstants = LayoutConstants.forMainScreen
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: layoutConstants.keyViewTopInset,
                                                           leading: layoutConstants.edgeHorizontalInset,
                                                           bottom: layoutConstants.keyViewBottomInset,
                                                           trailing: layoutConstants.edgeHorizontalInset)
        let keyRowsMargin: [NSDirectionalEdgeInsets] = (0..<keyRows.count).map {
            switch $0 {
            case 0: // First key row
                return NSDirectionalEdgeInsets(top: layoutConstants.keyViewTopInset, leading: 0, bottom: layoutConstants.keyRowGap / 2, trailing: 0)
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
    
    private func refreshCandidatePaneViewVisibility() {
        if _keyboardType == .emojis {
            destroyCandidatePaneView()
        } else {
            createCandidatePaneView()
            self.candidatePaneView?.isHidden = (candidateSource?.candidates.count ?? 0) == 0
        }
    }
    
    private func refreshKeyRowsVisibility() {
        if _keyboardType == .emojis || candidatePaneView?.mode ?? .row == .table {
            keyRows.forEach { $0.isHidden = true }
        } else {
            keyRows.forEach { $0.isHidden = false }
        }
    }
    
    private func refreshKeys() {
        keyRows.forEach { $0.needsInputModeSwitchKey = needsInputModeSwitchKey }
        
        switch _keyboardType {
        case let .alphabetic(shiftState):
            refreshAlphabeticKeys(shiftState)
        case .numeric:
            for (index, keyCaps) in numbersKeyCapRows.enumerated() {
                keyRows[index].setupRow(keyboardType: _keyboardType, keyCaps)
            }
        case .symbolic:
            for (index, keyCaps) in symbolsKeyCapRows.enumerated() {
                keyRows[index].setupRow(keyboardType: _keyboardType, keyCaps)
            }
        default:
            ()
        }
    }
    
    private func refreshAlphabeticKeys(_ shiftState: (KeyboardShiftState)) {
        for (index, var keyCaps) in englishLettersKeyCapRows.enumerated() {
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
            
            keyCaps = keyCaps.map { $0.map {
                switch $0 {
                case .character("F"), .character("G"), .character("H"),
                     .character("C"), .character("V"), .character("B"),
                     .character("f"), .character("g"), .character("h"),
                     .character("c"), .character("v"), .character("b"):
                    switch keyboardContextualType {
                    case .rime, .url(true):
                        if case .character(let c) = $0, Settings.cached.rimeSettings.toneInputMode == .longPress {
                            // Show tone keys.
                            return .characterWithTone(c)
                        } else {
                            return $0
                        }
                    default:
                        return $0
                    }
                case .contexualSymbols: return .contexualSymbols(keyboardContextualType)
                default:
                    return $0
                }
            } }
            
            keyRows[index].setupRow(keyboardType: _keyboardType, keyCaps)
        }
    }
    
    private func setupView() {
        refreshCandidatePaneViewVisibility()
        refreshKeyRowsVisibility()
        refreshKeys()
        refreshEmojiView()
    }
    
    private func refreshEmojiView() {
        if _keyboardType == .emojis {
            createAndShowEmojiView()
        } else {
            destroyEmojiView()
        }
    }
    
    private func createCandidatePaneView() {
        guard candidatePaneView == nil else { return }
        
        let candidatePaneView = CandidatePaneView()
        candidatePaneView.delegate = self

        addSubview(candidatePaneView)
        NSLayoutConstraint.activate([
            candidatePaneView.topAnchor.constraint(equalTo: self.topAnchor),
            candidatePaneView.leftAnchor.constraint(equalTo: self.leftAnchor),
            candidatePaneView.rightAnchor.constraint(equalTo: self.rightAnchor),
        ])
        
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
    
    func handleModeChange(isDisabled: Bool) {
        isEnabled = !isDisabled
    }
}

extension KeyboardView: CandidatePaneViewDelegate {
    func candidatePaneViewCandidateSelected(_ choice: Int) {
        delegate?.onCandidateSelected(choice)
    }
    
    func candidatePaneViewExpanded() {
        refreshCandidatePaneViewVisibility()
        refreshKeyRowsVisibility()
    }
    
    func candidatePaneViewCollapsed() {
        refreshCandidatePaneViewVisibility()
        refreshKeyRowsVisibility()
    }
    
    func candidatePaneCandidateLoaded() {
        refreshCandidatePaneViewVisibility()
    }
}

extension KeyboardView {
    // touchesBegan() is delayed if touches are near the screen edge.
    // We use GestureRecoginzer to workaround the delay.
    func touchesBeganFromGestureRecoginzer(_ touches: Set<UITouch>, with event: UIEvent?) {
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
        
        for touch in touches {
            let key = findTouchingView(touch, with: event) as? KeyView
            if let key = key {
                touchHandler.touchMoved(touch, key: key , with: event)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        for touch in touches {
            let key = findTouchingView(touch, with: event)
            touchHandler.touchEnded(touch, key: key as? KeyView, with: event)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
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

extension KeyboardView: EmojiViewDelegate {
    func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
        delegate?.handleKey(.emoji(emoji))
    }
    
    func emojiViewDidPressChangeKeyboardButton(_ emojiView: EmojiView) {
        keyboardType = .alphabetic(.lowercased)
    }
    
    func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView) {
        delegate?.handleKey(.backspace)
    }
}

extension KeyboardView: UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool {
        get { true }
    }
}
