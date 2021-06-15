//
//  KeyPadView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/14/21.
//

import Foundation
import UIKit

struct KeypadButtonProps {
    var keyCap: KeyCap
    let colRowSize: CGSize
    
    init(keyCap: KeyCap, colRowSize: CGSize? = nil) {
        self.keyCap = keyCap
        self.colRowSize = colRowSize ?? CGSize(width: 1, height: 1)
    }
}

class KeypadButton: UIButton {
    let colRowOrigin: CGPoint
    let colRowSize: CGSize
    var props: KeypadButtonProps
    var keyRepeatCounter: Int = 0
    let onAction: ((KeyboardAction) -> Void)
    
    private var originalBackgroundColor: UIColor?
    private var highlightedColor: UIColor? {
        didSet {
            setupBackgroundColor()
        }
    }
    private var keyRepeatTimer: Timer?
    
    deinit {
        keyRepeatTimer?.invalidate()
        keyRepeatTimer = nil
    }
    
    override var backgroundColor: UIColor? {
        get { super.backgroundColor }
        set {
            if super.backgroundColor != newValue {
                originalBackgroundColor = newValue
                setupBackgroundColor()
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            setupBackgroundColor()
        }
    }
    
    private func setupBackgroundColor() {
        if !isHighlighted {
            super.backgroundColor = originalBackgroundColor
        } else {
            super.backgroundColor = highlightedColor ?? originalBackgroundColor
        }
    }
    
    init(props: KeypadButtonProps, colRowOrigin: CGPoint, colRowSize: CGSize, onAction: @escaping ((KeyboardAction) -> Void)) {
        self.colRowOrigin = colRowOrigin
        self.colRowSize = colRowSize
        self.onAction = onAction
        self.props = props
        
        super.init(frame: .zero)
        
        layer.cornerRadius = 5
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.shadowColor = ButtonColor.keyShadowColor.resolvedColor(with: traitCollection).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 0.0
        layer.masksToBounds = false
        layer.cornerRadius = 5
        
        setup(props: props)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getSize(layoutConstants: LayoutConstants) -> CGSize {
        let unitSize = layoutConstants.keypadButtonUnitSize
        let numOfColumns = colRowSize.width
        let numOfRows = colRowSize.height
        return CGSize(
            width: unitSize.width * numOfColumns + layoutConstants.buttonGap * (numOfColumns - 1),
            height: unitSize.height * numOfRows + layoutConstants.buttonGap * (numOfRows - 1))
    }
    
    func setup(props: KeypadButtonProps) {
        self.props = props
        backgroundColor = props.keyCap.buttonBgColor
        highlightedColor = props.keyCap.keypadButtonBgHighlightedColor
        setTitleColor(props.keyCap.buttonFgColor, for: .normal)
        tintColor = props.keyCap.buttonFgColor
        titleLabel?.font = props.keyCap.buttonFont
        
        setTitle(props.keyCap.buttonText, for: .normal)
        setImage(props.keyCap.buttonImage, for: .normal)
        traitCollectionDidChange(nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if case .keyboardType(.emojis) = props.keyCap {
            setImage(traitCollection.userInterfaceStyle == .light ? ButtonImage.emojiKeyboardLight : ButtonImage.emojiKeyboardDark, for: .normal)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let action = props.keyCap.action
        guard action == .backspace else { return }
        
        AudioFeedbackProvider.lightFeedbackGenerator.impactOccurred()
        onAction(action)
        keyRepeatCounter = 0
        keyRepeatTimer = Timer.scheduledTimer(withTimeInterval: TouchHandler.keyRepeatInterval, repeats: true) { [weak self] timer in
            guard let self = self, self.keyRepeatTimer == timer else {
                timer.invalidate()
                return
            }
            
            if self.keyRepeatCounter > TouchHandler.keyRepeatInitialDelay {
                self.onAction(action)
            }
            self.keyRepeatCounter += 1
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        let action = props.keyCap.action
        guard props.keyCap.action != .backspace else {
            keyRepeatTimer?.invalidate()
            keyRepeatTimer = nil
            return
        }
        
        AudioFeedbackProvider.lightFeedbackGenerator.impactOccurred()
        onAction(action)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        keyRepeatTimer?.invalidate()
        keyRepeatTimer = nil
    }
}

class KeypadView: UIView, InputView {
    weak var delegate: KeyboardViewDelegate?
    
    private let leftButtonProps: [[KeypadButtonProps]] = [
        [ KeypadButtonProps(keyCap: .keyboardType(.numeric)) ],
        [ KeypadButtonProps(keyCap: .keyboardType(.alphabetic(.lowercased))) ],
        [ KeypadButtonProps(keyCap: .keyboardType(.symbolic)) ],
        [ KeypadButtonProps(keyCap: .keyboardType(.emojis)) ],
    ]
    
    private let rightButtonProps: [[KeypadButtonProps]] = [
        [ KeypadButtonProps(keyCap: .stroke("h")),
          KeypadButtonProps(keyCap: .stroke("s")),
          KeypadButtonProps(keyCap: .stroke("p")),
          KeypadButtonProps(keyCap: .backspace) ],
        [ KeypadButtonProps(keyCap: .stroke("n")),
          KeypadButtonProps(keyCap: .stroke("z")),
          KeypadButtonProps(keyCap: "?"),
          KeypadButtonProps(keyCap: .none) ],
        [ KeypadButtonProps(keyCap: ","), KeypadButtonProps(keyCap: "."), KeypadButtonProps(keyCap: "!"), KeypadButtonProps(keyCap: .returnKey(.default), colRowSize: CGSize(width: 1, height: 2)) ],
        [ KeypadButtonProps(keyCap: .space(.space), colRowSize: CGSize(width: 3, height: 1)) ],
    ]
    
    private weak var statusMenu: StatusMenu?
    private weak var candidatePaneView: CandidatePaneView?
    
    private var leftButtons: [[KeypadButton]] = []
    private var rightButtons: [[KeypadButton]] = []
    
    private var candidateOrganizer: CandidateOrganizer
    private var _state: KeyboardState
    var state: KeyboardState {
        get { _state }
        set { changeState(prevState: _state, newState: newValue) }
    }
    
    init(state: KeyboardState, candidateOrganizer: CandidateOrganizer) {
        self._state = state
        self.candidateOrganizer = candidateOrganizer
        super.init(frame: .zero)
        
        backgroundColor = .clearInteractable
        insetsLayoutMarginsFromSafeArea = false
        isMultipleTouchEnabled = true
        preservesSuperviewLayoutMargins = false
        
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    private func initView() {
        leftButtons = initButtons(buttonLayouts: leftButtonProps)
        rightButtons = initButtons(buttonLayouts: rightButtonProps)
        
        let candidatePaneView = CandidatePaneView(keyboardState: state, candidateOrganizer: candidateOrganizer)
        candidatePaneView.delegate = self
        addSubview(candidatePaneView)
        self.candidatePaneView = candidatePaneView
    }
    
    private func initButtons(buttonLayouts: [[KeypadButtonProps]]) -> [[KeypadButton]] {
        var buttons: [[KeypadButton]] = []
        var x: CGFloat = 0, y: CGFloat = 0
        for row in buttonLayouts {
            var buttonRow: [KeypadButton] = []
            for props in row {
                let button = KeypadButton(props: props, colRowOrigin: CGPoint(x: x, y: y), colRowSize: props.colRowSize, onAction: handleKey)
                addSubview(button)
                buttonRow.append(button)
                x += 1
            }
            buttons.append(buttonRow)
            y += 1
        }
        return buttons
    }
    
    private func setupButtons() {
        let isFullShape = state.keyboardContextualType == .chinese
        for row in rightButtons {
            for button in row {
                var props = button.props
                switch props.keyCap.action {
                case ",", "，": props.keyCap = isFullShape ? "，" : ","
                case ".", "。": props.keyCap = isFullShape ? "。" : "."
                case "?", "？": props.keyCap = isFullShape ? "？" : "?"
                case "!", "！": props.keyCap = isFullShape ? "！" : "!"
                default: ()
                }
                button.setup(props: props)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layoutConstants = LayoutConstants.forMainScreen
        layoutButtons(leftButtons, initialX: layoutConstants.edgeHorizontalInset, layoutConstants: layoutConstants)
        layoutButtons(rightButtons, initialX: layoutConstants.edgeHorizontalInset + layoutConstants.buttonGap + layoutConstants.keypadButtonUnitSize.width, layoutConstants: layoutConstants)
        
        layoutCandidateSubviews(layoutConstants)
        layoutStatusMenu()
    }
    
    private func layoutButtons(_ buttons: [[KeypadButton]], initialX: CGFloat, layoutConstants: LayoutConstants) {
        var x: CGFloat = initialX, y: CGFloat = LayoutConstants.keyViewTopInset + layoutConstants.autoCompleteBarHeight
        
        for row in buttons {
            x = initialX
            for button in row {
                let origin = CGPoint(x: x, y: y)
                let size = button.getSize(layoutConstants: layoutConstants)
                button.frame = CGRect(origin: origin, size: size)
                x += size.width + layoutConstants.buttonGap
            }
            y += layoutConstants.keypadButtonUnitSize.height + layoutConstants.buttonGap
        }
    }

    private func changeState(prevState: KeyboardState, newState: KeyboardState) {
        let isViewDirty = prevState.keyboardContextualType != newState.keyboardContextualType
        
        _state = newState
        if isViewDirty { setupButtons() }
        
        candidatePaneView?.keyboardState = state
    }
    
    private func layoutCandidateSubviews(_ layoutConstants: LayoutConstants) {
        guard let candidatePaneView = candidatePaneView else { return }
        let height = candidatePaneView.mode == .row ? layoutConstants.autoCompleteBarHeight : bounds.height
        candidatePaneView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: bounds.width, height: height))
    }
    
    private func layoutStatusMenu() {
        guard let statusMenu = statusMenu else { return }
        
        let size = statusMenu.intrinsicContentSize
        let origin = CGPoint(x: frame.width - size.width, y: LayoutConstants.forMainScreen.autoCompleteBarHeight)
        let frame = CGRect(origin: origin, size: size)
        statusMenu.frame = frame.offsetBy(dx: -StatusMenu.xInset, dy: 0)
    }
    
    func candidatePanescrollToNextPageInRowMode() {
        candidatePaneView?.scrollToNextPageInRowMode()
    }
}


extension KeypadView: CandidatePaneViewDelegate {
    func candidatePaneViewCandidateSelected(_ choice: IndexPath) {
        delegate?.handleKey(.selectCandidate(choice))
    }
    
    func candidatePaneViewExpanded() {
        setNeedsLayout()
        refreshButtonsVisibility(buttons: leftButtons)
        refreshButtonsVisibility(buttons: rightButtons)
    }
    
    func candidatePaneViewCollapsed() {
        setNeedsLayout()
        refreshButtonsVisibility(buttons: leftButtons)
        refreshButtonsVisibility(buttons: rightButtons)
    }
    
    private func refreshButtonsVisibility(buttons: [[KeypadButton]]) {
        let isButtonVisible = candidatePaneView?.mode ?? .row == .row
        
        buttons.forEach({
            $0.forEach({ b in
                b.isHidden = !isButtonVisible
            })
        })
    }
    
    func candidatePaneCandidateLoaded() {
    }
    
    func handleKey(_ action: KeyboardAction) {
        if case .keyboardType(.alphabetic) = action, case .alphabetic = state.keyboardType {
            delegate?.handleKey(.toggleInputMode)
        } else {
            delegate?.handleKey(action)
        }
    }
    
    func handleStatusMenu(from: UIView, with: UIEvent?) -> Bool {
        guard candidatePaneView?.shouldShowStatusMenu ?? false else {
            hideStatusMenu()
            return false
        }
        if let touch = with?.allTouches?.first, touch.view == from {
            switch touch.phase {
            case .began, .moved, .stationary:
                showStatusMenu()
                statusMenu?.touchesMoved([touch], with: with)
                return true
            case .ended:
                statusMenu?.touchesEnded([touch], with: with)
                hideStatusMenu()
                return false
            case .cancelled:
                statusMenu?.touchesCancelled([touch], with: with)
                hideStatusMenu()
                return false
            default: ()
            }
        }
        return statusMenu != nil
    }
    
    private func showStatusMenu() {
        guard statusMenu == nil else { return }
        AudioFeedbackProvider.softFeedbackGenerator.impactOccurred()
        
        var menuRows: [[KeyCap]] =  [
            [ .changeSchema(.yale), .changeSchema(.jyutping) ],
            [ .changeSchema(.cangjie), .changeSchema(.quick) ],
            [ .changeSchema(.mandarin), .changeSchema(.stroke) ],
        ]
        if state.activeSchema.supportMixedMode {
            menuRows[menuRows.count - 1].append(.switchToEnglishMode)
        }
        let statusMenu = StatusMenu(menuRows: menuRows)
        statusMenu.handleKey = delegate?.handleKey

        addSubview(statusMenu)
        self.statusMenu = statusMenu
    }
    
    private func hideStatusMenu() {
        statusMenu?.removeFromSuperview()
    }
}
