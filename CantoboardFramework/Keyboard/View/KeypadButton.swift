//
//  KeypadButton.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/15/21.
//

import Foundation
import UIKit

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
        
        FeedbackProvider.lightImpact.impactOccurred()
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
        
        FeedbackProvider.lightImpact.impactOccurred()
        onAction(action)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        keyRepeatTimer?.invalidate()
        keyRepeatTimer = nil
    }
}
