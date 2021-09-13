//
//  StockboardKey.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/16/21.
//

import Foundation
import UIKit

class KeyView: HighlightableButton {
    private static let contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 4, right: 6)
    private static let swipeDownMinCutOffYRatio: CGFloat = 0.25
    private static let swipeDownMaxCutOffYRatio: CGFloat = 0.6
    
    private var keyHintLayer: KeyHintLayer?
    private var swipeDownHintLayer: KeyHintLayer?
    private var swipeDownPercentage: CGFloat = 0 {
        didSet {
            setNeedsLayout()
            updateColorsAccordingToSwipeDownPercentage()
        }
    }
    
    private var popupView: KeyPopupView?
    private var isPopupInLongPressMode: Bool?
    private var touchBeginPosition: CGPoint?
    private var shouldAcceptLongPress: Bool = false
    
    private(set) var keyCap: KeyCap = .none
    private var keyboardIdiom: LayoutIdiom = LayoutConstants.forMainScreen.idiom
    private var keyboardType: KeyboardType = .none
    private var isPadTopRowButton = false
    private var action: KeyboardAction = .none
    
    var isKeyEnabled: Bool = true {
        didSet {
            setupView()
        }
    }
    
    var selectedAction: KeyboardAction = .none
    
    var hitTestFrame: CGRect?
    
    var isLabelHidden: Bool {
        get { titleLabel?.isHidden ?? true }
        set { titleLabel?.isHidden = newValue }
    }
    
    var hasInputAcceptingPopup: Bool {
        popupView?.keyCaps.count ?? 0 > 1
    }
    
    // TODO Remove
    var shouldDisablePopup: Bool = false
    
    var heightClearance: CGFloat?
    
    private weak var layoutConstants: Reference<LayoutConstants>?
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    init(layoutConstants: Reference<LayoutConstants>) {
        self.layoutConstants = layoutConstants
        super.init(frame: .zero)
        setupUIButton()
    }
    
    private func setupUIButton() {
        setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .light), forImageIn: .normal)
        
        isUserInteractionEnabled = true
        layer.cornerRadius = 5
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.shadowColor = ButtonColor.keyShadowColor.resolvedColor(with: traitCollection).cgColor
        layer.shadowRadius = 0.0
        layer.masksToBounds = false
        layer.cornerRadius = 5
    }
    
    func setKeyCap(_ keyCap: KeyCap, keyboardIdiom: LayoutIdiom, keyboardType: KeyboardType, isPadTopRowButton: Bool = false) {
        guard keyCap != self.keyCap || keyboardIdiom != self.keyboardIdiom || keyboardType != self.keyboardType else { return }
        self.keyCap = keyCap
        self.keyboardIdiom = keyboardIdiom
        self.keyboardType = keyboardType
        self.action = keyCap.action
        self.selectedAction = keyCap.action
        self.isPadTopRowButton = isPadTopRowButton
        setupView()
        swipeDownPercentage = 0
    }
        
    internal func setupView() {
        backgroundColor = keyCap.buttonBgColor
        
        let foregroundColor = keyCap.buttonFgColor
        setTitleColor(foregroundColor, for: .normal)
        tintColor = foregroundColor
        contentEdgeInsets = Self.contentEdgeInsets
        titleEdgeInsets = keyCap.buttonTitleInset
        
        var maskedCorners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        var shadowOpacity: Float = 1.0
        var buttonHintTitle = keyCap.buttonHint
        var setHighlightedBackground = false
        
        if !isKeyEnabled {
            setImage(nil, for: .normal)
            setTitle(nil, for: .normal)
            titleLabel?.text = nil
            if case .shift = keyCap {
                // Hide the highlighted color in swipe mode.
                backgroundColor = ButtonColor.systemKeyBackgroundColor
            }
            shadowOpacity = 0
            buttonHintTitle = nil
        } else if popupView != nil {
            setImage(nil, for: .normal)
            setTitle(nil, for: .normal)
            titleLabel?.text = nil
            backgroundColor = ButtonColor.popupBackgroundColor
            maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else if let buttonText = keyCap.buttonText {
            setImage(nil, for: .normal)
            setTitle(buttonText, for: .normal)
            titleLabel?.font = keyCap.buttonFont
            titleLabel?.baselineAdjustment = .alignCenters
            titleLabel?.lineBreakMode = .byClipping
            titleLabel?.adjustsFontSizeToFitWidth = true
            setHighlightedBackground = true
        } else {
            var buttonImage = keyCap.buttonImage
            if keyCap == .keyboardType(.emojis) {
                // Special handling for emoji icon. We use different symbols in light/dark mode.
                let isDarkMode = traitCollection.userInterfaceStyle == .dark
                buttonImage = isDarkMode ? ButtonImage.emojiKeyboardDark : ButtonImage.emojiKeyboardLight
            }
            setImage(buttonImage, for: .normal)
            setTitle(nil, for: .normal)
            titleLabel?.text = nil
            setHighlightedBackground = true
        }
        
        let keyboardViewLayout = keyboardIdiom.keyboardViewLayout
        if let padSwipeDownKeyCap = keyboardViewLayout.getSwipeDownKeyCap(keyCap: keyCap, keyboardType: keyboardType) {
            if swipeDownHintLayer == nil {
                let swipeDownHintLayer = KeyHintLayer()
                layer.addSublayer(swipeDownHintLayer)
                self.swipeDownHintLayer = swipeDownHintLayer
            }
            swipeDownHintLayer?.string = padSwipeDownKeyCap.buttonText
        } else {
            swipeDownHintLayer?.removeFromSuperlayer()
            swipeDownHintLayer = nil
        }
        
        if isPadTopRowButton {
            titleLabel?.font = titleLabel?.font.withSize(15)
        }
        
        if setHighlightedBackground {
            if keyboardIdiom == .phone {
                highlightedColor = keyCap.buttonBgHighlightedColor
            } else {
                highlightedColor = keyCap.buttonBgHighlightedColor ?? .systemGray3
            }
        } else {
            highlightedColor = nil
        }
        
        setupKeyHint(keyCap, buttonHintTitle, keyCap.buttonHintFgColor)
        
        layer.maskedCorners = maskedCorners
        layer.shadowOpacity = shadowOpacity
        
        if case .placeholder = keyCap {
            isHidden = true
        } else {
            isHidden = false
        }
        
        // isUserInteractionEnabled = action == .nextKeyboard
        // layoutPopupView()
        setNeedsLayout()
    }
    
    private func setupKeyHint(_ keyCap: KeyCap, _ buttonHintTitle: String?, _ foregroundColor: UIColor) {
        if let buttonHintTitle = buttonHintTitle {
            if keyHintLayer == nil {
                let keyHintLayer = KeyHintLayer()
                keyHintLayer.foregroundColor = keyCap.buttonHintFgColor.resolvedColor(with: traitCollection).cgColor
                self.keyHintLayer = keyHintLayer
                layer.addSublayer(keyHintLayer)
                keyHintLayer.layoutSublayers()
            }
            self.keyHintLayer?.setup(keyCap: keyCap, hintText: buttonHintTitle)
        } else {
            keyHintLayer?.removeFromSuperlayer()
            keyHintLayer = nil
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let hitTestFrame = hitTestFrame {
            if isHidden || window == nil { return false }
            // Translate hit test frame to hit test bounds.
            let hitTestBounds = hitTestFrame.offsetBy(dx: -frame.origin.x, dy: -frame.origin.y)
            return hitTestBounds.contains(point)
        } else {
            return super.point(inside: point, with: event)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.shadowColor = ButtonColor.keyShadowColor.resolvedColor(with: traitCollection).cgColor
        
        if keyCap == .keyboardType(.emojis) { setupView() }
        
        if let keyHintLayer = keyHintLayer {
            keyHintLayer.foregroundColor = keyCap.buttonHintFgColor.resolvedColor(with: traitCollection).cgColor
        }
        
        updateColorsAccordingToSwipeDownPercentage()
    }
    
    override func layoutSubviews() {
        if let keyHintLayer = keyHintLayer {
            keyHintLayer.isHidden = popupView != nil
            layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.topRightInsets)
        }
        
        if let swipeDownHintLayer = swipeDownHintLayer {
            let swipeDownHintLayerHeight = (1 - swipeDownPercentage) * bounds.height * 0.3 + swipeDownPercentage * bounds.height * 0.5
            
            let fullySwipedDownYOffset = bounds.height / 2 - swipeDownHintLayerHeight / 2
            let yOffset = (1 - swipeDownPercentage) * contentEdgeInsets.top + swipeDownPercentage * fullySwipedDownYOffset
            
            layout(textLayer: swipeDownHintLayer, centeredWithYOffset: yOffset, height: swipeDownHintLayerHeight)
            contentVerticalAlignment = .bottom
        } else {
            contentVerticalAlignment = keyboardIdiom.isPadFull &&
                !(keyCap.keyCapType == .input || keyCap.keyCapType == .space || isPadTopRowButton) ? .bottom : .center
        }
        
        super.layoutSubviews()
        layoutPopupView()
    }
    
    private func updateColorsAccordingToSwipeDownPercentage() {
        if let originalTextColor = titleColor(for: .normal) {
            setTitleColor(originalTextColor.withAlphaComponent(originalTextColor.alpha * (1 - swipeDownPercentage)), for: .highlighted)
            
            if let swipeDownHintLayer = swipeDownHintLayer {
                let isSwipeDownKeyShiftMorphing = keyboardIdiom.keyboardViewLayout.isSwipeDownKeyShiftMorphing(keyCap: keyCap)
                let foregroundColor = isSwipeDownKeyShiftMorphing ? UIColor.label : UIColor.systemGray
                swipeDownHintLayer.foregroundColor = foregroundColor.interpolateRGBColorTo(originalTextColor, fraction: swipeDownPercentage)?.cgColor
            }
        }
    }
    
    private func layoutPopupView() {
        guard let popupView = popupView else { return }
        popupView.heightClearance = heightClearance
        popupView.layoutView()
        
        let popupViewSize = popupView.bounds.size
        let layoutOffsetX = popupView.leftAnchorX
        let popupViewFrame = CGRect(origin: CGPoint(x: -layoutOffsetX, y: -popupViewSize.height + 1), size: popupViewSize)
        popupView.frame = popupViewFrame
    }
}

extension KeyView {
    // Forward all touch events to the superview.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesCancelled(touches, with: event)
        isHighlighted = false
    }
}

extension KeyView {
    func keyTouchBegan(_ touch: UITouch) {
        isHighlighted = true
        selectedAction = keyCap.action
        updatePopup(isLongPress: false)
        
        touchBeginPosition = touch.location(in: self)
        shouldAcceptLongPress = true
    }
    
    func keyTouchMoved(_ touch: UITouch) {
        if let padSwipeDownKeyCap = keyboardIdiom.keyboardViewLayout.getSwipeDownKeyCap(keyCap: keyCap, keyboardType: keyboardType),
           let touchBeginPosition = touchBeginPosition {
            // Handle iPad swipe down.
            let point = touch.location(in: self)
            let delta = point - touchBeginPosition
            
            swipeDownPercentage = min(max(0, delta.y / bounds.height), 1)
            
            let swipeDownThreshold = bounds.height * Self.swipeDownMaxCutOffYRatio
            if delta.y > bounds.height * Self.swipeDownMinCutOffYRatio {
                shouldAcceptLongPress = false
                removePopup()
                
                selectedAction = delta.y >= swipeDownThreshold ? padSwipeDownKeyCap.action : keyCap.action
                return
            }
        }
        
        if let popupView = popupView {
            popupView.updateSelectedAction(touch)
            selectedAction = popupView.selectedAction
        }
    }
    
    func keyTouchEnded() {
        isHighlighted = false
        touchBeginPosition = nil
        swipeDownPercentage = 0
        
        removePopup()
    }
    
    func keyLongPressed(_ touch: UITouch) {
        guard shouldAcceptLongPress else { return }
        updatePopup(isLongPress: true)
    }
    
    private func createPopupViewIfNecessary() {
        guard let layoutConstants = layoutConstants else { return }
        if popupView == nil {
            let popupView = KeyPopupView(layoutConstants: layoutConstants)
            addSubview(popupView)
            
            self.popupView = popupView
        }
    }
    
    private func updatePopup(isLongPress: Bool) {
        guard keyCap.hasPopup && !shouldDisablePopup else { return }
        // iPad does not have popup preview.
        if keyboardIdiom.isPad && !isLongPress { return }
        
        // Special case, do not show "enhance" keycap of the emoji button.
        if keyCap == .keyboardType(.emojis) && !isLongPress {
            return
        }
        
        let keyCaps = computeKeyCap(isLongPress: isLongPress)
        // On iPad, shows popup only in long press mode and if there are multiple choices.
        if keyboardIdiom.isPad && keyCaps.count == 1 {
            return
        }
        
        createPopupViewIfNecessary()
        guard let popupView = popupView else { return }
        guard isLongPress != isPopupInLongPressMode else { return }
        
        let popupDirection = computePopupDirection()
        
        let defaultKeyCapIndex: Int
        defaultKeyCapIndex = keyCaps.firstIndex(where: { $0.buttonText == keyCap.defaultChildKeyCapTitle }) ?? 0
        popupView.setup(keyCaps: keyCaps, defaultKeyCapIndex: defaultKeyCapIndex, direction: popupDirection)
        selectedAction = popupView.selectedAction
        
        isPopupInLongPressMode = isLongPress
        setupView()
    }
    
    private func removePopup() {
        isPopupInLongPressMode = nil
        popupView?.removeFromSuperview()
        popupView = nil
        
        // Restore lables and rounded corners.
        setupView()
    }
    
    private func computePopupDirection() -> KeyPopupView.PopupDirection {
        guard let superview = superview else { return .middle }
        
        let screenEdgeThreshold = bounds.width / 2

        let keyViewFrame = convert(bounds, to: superview)
        if keyViewFrame.minX < screenEdgeThreshold {
            // Special case, for key 1, it has 10 children.
            if self.keyCap.childrenKeyCaps.count > 9 {
                return .middle
            } else {
                return .right
            }
        }
        
        if superview.bounds.width - keyViewFrame.maxX < screenEdgeThreshold {
            return .left
        }
        
        let isKeyOnTheLeft = keyViewFrame.midX / superview.bounds.width <= 0.5
        return isKeyOnTheLeft ? .middle : .middleExtendLeft
    }
    
    private func computeKeyCap(isLongPress: Bool) -> [KeyCap] {
        if isLongPress {
            return keyCap.childrenKeyCaps
        } else {
            return [keyCap]
        }
    }
}
