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
    let autoSuggestionOverride: AutoSuggestionType?
    
    init(keyCap: KeyCap, colRowSize: CGSize? = nil, autoSuggestionOverride: AutoSuggestionType? = nil) {
        self.keyCap = keyCap
        self.colRowSize = colRowSize ?? CGSize(width: 1, height: 1)
        self.autoSuggestionOverride = autoSuggestionOverride
    }
}

class KeypadView: UIView, BaseKeyboardView {
    weak var delegate: KeyboardViewDelegate?
    
    private let leftButtonProps: [[KeypadButtonProps]] = [
        [ KeypadButtonProps(keyCap: .keyboardType(.numeric)) ],
        [ KeypadButtonProps(keyCap: .placeholder(.none)) ],
        [ KeypadButtonProps(keyCap: .keyboardType(.symbolic)) ],
        [ KeypadButtonProps(keyCap: .keyboardType(.emojis)) ],
    ]
    
    private let rightButtonStrokeProps: [[KeypadButtonProps]] = [
        [ KeypadButtonProps(keyCap: .stroke("h")),
          KeypadButtonProps(keyCap: .stroke("s")),
          KeypadButtonProps(keyCap: .stroke("p")),
          KeypadButtonProps(keyCap: .backspace) ],
        [ KeypadButtonProps(keyCap: .stroke("n")),
          KeypadButtonProps(keyCap: .stroke("z")),
          KeypadButtonProps(keyCap: "?") ],
        [ KeypadButtonProps(keyCap: ","),
          KeypadButtonProps(keyCap: "."),
          KeypadButtonProps(keyCap: "!"),
          KeypadButtonProps(keyCap: .returnKey(.default), colRowSize: CGSize(width: 1, height: 2)) ],
        [ KeypadButtonProps(keyCap: .space(.space), colRowSize: CGSize(width: 3, height: 1)) ],
    ]
    
    private let rightButtonJyutPingProps: [[KeypadButtonProps]] = [
        [ KeypadButtonProps(keyCap: .combo(["，", "。", "？", "！"]), autoSuggestionOverride: .keypadSymbols),
          KeypadButtonProps(keyCap: .jyutPing10Keys("A")),
          KeypadButtonProps(keyCap: .jyutPing10Keys("D")),
          KeypadButtonProps(keyCap: .backspace) ],
        [ KeypadButtonProps(keyCap: .jyutPing10Keys("G")),
          KeypadButtonProps(keyCap: .jyutPing10Keys("J")),
          KeypadButtonProps(keyCap: .jyutPing10Keys("M")),
          KeypadButtonProps(keyCap: .keypadRimeDelimiter)],
        [ KeypadButtonProps(keyCap: .jyutPing10Keys("P")),
          KeypadButtonProps(keyCap: .jyutPing10Keys("T")),
          KeypadButtonProps(keyCap: .jyutPing10Keys("W")), KeypadButtonProps(keyCap: .returnKey(.default), colRowSize: CGSize(width: 1, height: 2)) ],
        [ KeypadButtonProps(keyCap: .space(.space), colRowSize: CGSize(width: 3, height: 1)) ],
    ]
    
    private weak var candidatePaneView: CandidatePaneView?
    public var layoutConstants: Reference<LayoutConstants> = Reference(LayoutConstants.forMainScreen)
    
    internal weak var statusMenu: StatusMenu?
    
    private var touchHandler: TouchHandler?
    private var leftButtons: [[KeypadButton]] = []
    private var rightButtons: [[KeypadButton]] = []
    
    public var candidateOrganizer: CandidateOrganizer? {
        didSet {
            candidatePaneView?.candidateOrganizer = candidateOrganizer
        }
    }
    
    private var _state: KeyboardState
    var state: KeyboardState {
        get { _state }
        set { changeState(prevState: _state, newState: newValue) }
    }
    
    init(state: KeyboardState) {
        self._state = state
        super.init(frame: .zero)
        
        backgroundColor = .clearInteractable
        insetsLayoutMarginsFromSafeArea = false
        isMultipleTouchEnabled = true
        preservesSuperviewLayoutMargins = false
        
        initView()
    }
    
    override func didMoveToSuperview() {
        if superview == nil {
            touchHandler = nil
        } else {
            let touchHandler = TouchHandler(keyboardView: self, keyboardIdiom: state.keyboardIdiom)
            touchHandler.isInKeyboardMode = !state.activeSchema.is10Keys
            self.touchHandler = touchHandler
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    private func initView() {
        let candidatePaneView = CandidatePaneView(keyboardState: state, layoutConstants: layoutConstants)
        candidatePaneView.candidateOrganizer = candidateOrganizer
        candidatePaneView.delegate = self
        addSubview(candidatePaneView)
        candidatePaneView.setupButtons()

        self.candidatePaneView = candidatePaneView
        
        if (state.isKeyboardAppearing) {
            setupButtons()
        }
    }
    
    private func initButtons(buttonLayouts: [[KeypadButtonProps]], existingButtons: [[KeypadButton]]) -> [[KeypadButton]] {
        var existingButtons = existingButtons.flatMap { $0 }
        var buttons: [[KeypadButton]] = []
        var x: CGFloat = 0, y: CGFloat = 0
        
        let isFullWidth = !state.keyboardContextualType.halfWidthSymbol
        
        for row in buttonLayouts {
            var buttonRow: [KeypadButton] = []
            for props in row {
                let button: KeypadButton
                if !existingButtons.isEmpty {
                    button = existingButtons.removeFirst()
                } else {
                    button = KeypadButton()
                    button.titleLabel?.adjustsFontSizeToFitWidth = true
                    addSubview(button)
                }
                
                var keyCap = props.keyCap
                switch keyCap.action {
                case ",", "，": keyCap = isFullWidth ? "，" : ","
                case ".", "。": keyCap = isFullWidth ? "。" : "."
                case "?", "？": keyCap = isFullWidth ? "？" : "?"
                case "!", "！": keyCap = isFullWidth ? "！" : "!"
                default: ()
                }
                
                button.colRowOrigin = CGPoint(x: x, y: y)
                button.colRowSize = props.colRowSize
                button.setKeyCap(keyCap, keyboardState: state)
                button.highlightedColor = keyCap.buttonBgHighlightedColor
                button.autoSuggestionOverride = props.autoSuggestionOverride
                buttonRow.append(button)
                x += 1
            }
            buttons.append(buttonRow)
            y += 1
        }
        existingButtons.forEach { $0.removeFromSuperview() }
        return buttons
    }
    
    private func setupButtons() {
        touchHandler?.isInKeyboardMode = !state.activeSchema.is10Keys
        
        leftButtons = initButtons(buttonLayouts: leftButtonProps, existingButtons: leftButtons)
        
        let rightButtonProps = state.activeSchema == .stroke ? rightButtonStrokeProps : rightButtonJyutPingProps
        rightButtons = initButtons(buttonLayouts: rightButtonProps, existingButtons: rightButtons)
    }
    
    override func layoutSubviews() {
        let layoutConstants = layoutConstants.ref
        
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: layoutConstants.keyboardViewInsets.top,
                                                           leading: layoutConstants.keyboardViewInsets.left,
                                                           bottom: layoutConstants.keyboardViewInsets.bottom,
                                                           trailing: layoutConstants.keyboardViewInsets.right)
        
        super.layoutSubviews()
        
        layoutButtons(leftButtons, initialX: layoutConstants.keyboardViewInsets.left, layoutConstants: layoutConstants)
        layoutButtons(rightButtons, initialX: layoutConstants.keyboardViewInsets.left + layoutConstants.buttonGapX + layoutConstants.keypadButtonUnitSize.width, layoutConstants: layoutConstants)
        
        layoutCandidateSubviews(layoutConstants)
        layoutStatusMenu()
    }
    
    private func layoutButtons(_ buttons: [[KeypadButton]], initialX: CGFloat, layoutConstants: LayoutConstants) {
        var x: CGFloat = initialX, y: CGFloat = LayoutConstants.keyboardViewTopInset + layoutConstants.autoCompleteBarHeight
        
        for row in buttons {
            x = initialX
            for button in row {
                let origin = CGPoint(x: x, y: y)
                let size = button.getSize(layoutConstants: layoutConstants)
                button.frame = CGRect(origin: origin, size: size)
                x += size.width + layoutConstants.buttonGapX
            }
            y += layoutConstants.keypadButtonUnitSize.height + layoutConstants.buttonGapX
        }
    }

    private func changeState(prevState: KeyboardState, newState: KeyboardState) {
        let isViewDirty = prevState.keyboardContextualType != newState.keyboardContextualType ||
            prevState.isKeyboardAppearing != newState.isKeyboardAppearing ||
            prevState.keyboardType != newState.keyboardType ||
            prevState.activeSchema != newState.activeSchema
        
        _state = newState
        if isViewDirty { setupButtons() }
        
        candidatePaneView?.keyboardState = state
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
    
    func scrollCandidatePaneToNextPageInRowMode() {
        candidatePaneView?.scrollToNextPageInRowMode()
    }
    
    func setPreserveCandidateOffset() {
        candidatePaneView?.setPreserveCandidateOffset()
    }
    
    func changeCandidatePaneMode(_ mode: CandidatePaneView.Mode) {
        candidatePaneView?.changeMode(mode)
    }
}

extension KeypadView: CandidatePaneViewDelegate, StatusMenuHandler {
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
        // if case .keyboardType(.alphabetic) = action, case .alphabetic = state.keyboardType {
        delegate?.handleKey(action)
    }
    
    var statusMenuOriginY: CGFloat {
        layoutConstants.ref.autoCompleteBarHeight
    }
    
    var keyboardSize: CGSize {
        layoutConstants.ref.keyboardSize
    }
}

extension KeypadView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first,
              let keypadButton = touch.view as? KeyView else { return }
        
        // Reset other combo buttons.
        let allButtons = (leftButtons + rightButtons).flatMap { $0 }
        allButtons.forEach { button in
            if keypadButton !== button {
                button.updateComboMode(enabled: false)
            }
        }
        
        touchHandler?.touchBegan(touch, key: keypadButton, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first,
              let keypadButton = touch.view as? KeyView else { return }
        
        touchHandler?.touchMoved(touch, key: keypadButton, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first,
              let keypadButton = touch.view as? KeyView else { return }
        
        touchHandler?.touchEnded(touch, key: keypadButton, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard let touch = touches.first else { return }
        
        touchHandler?.touchCancelled(touch, with: event)
    }
}
