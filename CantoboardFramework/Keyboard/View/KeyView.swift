//
//  StockboardKey.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/16/21.
//

import Foundation
import UIKit

class KeyView: HighlightableButton, CAAnimationDelegate {
    private static let swipeDownMinCutOffYRatio: CGFloat = 0.2
    private static let swipeDownMaxCutOffYRatio: CGFloat = 0.5
    private static let swipeDownFullYRatio: CGFloat = 0.8
    private static let padLandscapeFontRatio = 1.3
    private static let morphingKeyFontRatio = 0.9
    
    private var keyHintLayer: KeyHintLayer?
    private var swipeDownHintLayer: KeyHintLayer?
    private var swipeDownPercentage: CGFloat = 0 {
        didSet {
            setNeedsLayout()
            updateColorsAccordingToSwipeDownPercentage()
        }
    }
    private var titleLabelFontSize: CGFloat = 24
    
    private var popupView: KeyPopupView?
    private var isPopupInLongPressMode: Bool?
    private var touchBeginPosition: CGPoint?
    private var shouldAcceptLongPress: Bool = false
    
    private(set) var keyCap: KeyCap = .none
    private var keyboardState: KeyboardState? = nil
    private var isPadTopRowButton = false
    private var action: KeyboardAction = .none
    
    // TODO Remove this field and check keyboardState
    var isKeyEnabled: Bool = true {
        didSet {
            setupView()
        }
    }
    
    var selectedAction: KeyboardAction = .none
    
    var hitTestFrame: CGRect?
    
    var hasInputAcceptingPopup: Bool {
        popupView?.keyCaps.count ?? 0 > 1
    }
    
    private var firstFrame = false
    
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
    
    override public class var layerClass: AnyClass {
        return SwipeDownLayer.self
    }
    
    private func setupUIButton() {
        setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .light), forImageIn: .normal)
        
        isUserInteractionEnabled = true
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.shadowRadius = 0.0
        layer.masksToBounds = false
    }
    
    func setKeyCap(_ keyCap: KeyCap, keyboardState newState: KeyboardState, isPadTopRowButton: Bool = false) {
        let hasStateChanged = keyboardState == nil ||
            keyboardState?.keyboardIdiom != newState.keyboardIdiom ||
            keyboardState?.keyboardType != newState.keyboardType ||
            keyboardState?.keyboardContextualType != newState.keyboardContextualType ||
            keyboardState?.isPortrait != newState.isPortrait
        guard keyCap != self.keyCap || hasStateChanged else { return }
        
        self.keyCap = keyCap
        self.action = keyCap.action
        self.selectedAction = keyCap.action
        self.isPadTopRowButton = isPadTopRowButton
        self.keyboardState = newState
        
        swipeDownPercentage = 0
        setupView()
    }
    
    internal func setupView() {
        guard let keyboardState = keyboardState,
              let layoutConstants = layoutConstants else { return }
        let keyboardIdiom = keyboardState.keyboardIdiom
        
        backgroundColor = keyCap.buttonBgColor
        
        let foregroundColor = keyCap.buttonFgColor
        setTitleColor(foregroundColor, for: .normal)
        setTitleColor(ButtonColor.placeholderKeyForegroundColor, for: .disabled)
        tintColor = foregroundColor
        contentEdgeInsets = layoutConstants.ref.keyViewInsets
        titleEdgeInsets = keyCap.buttonTitleInset
        layer.cornerRadius = layoutConstants.ref.cornerRadius
        titleLabelFontSize = isPadTopRowButton ? 17 : layoutConstants.ref.getButtonFontSize(keyCap.unescaped)
        if keyboardIdiom.isPad && !keyboardState.isPortrait {
            titleLabelFontSize *= Self.padLandscapeFontRatio
        }
        
        var maskedCorners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        var shadowOpacity: Float = 1.0
        var buttonHintTitle = keyCap.buttonHint
        var setHighlightedBackground = false
        
        setImage(nil, for: .normal)
        setImage(nil, for: .highlighted)
        setTitle(nil, for: .normal)
        imageView?.image = nil
        titleLabel?.text = nil
        
        if !isKeyEnabled {
            if case .shift = keyCap {
                // Hide the highlighted color in swipe mode.
                backgroundColor = ButtonColor.systemKeyBackgroundColor
            }
            shadowOpacity = 0
            buttonHintTitle = nil
        } else if popupView != nil && keyboardIdiom == .phone {
            backgroundColor = ButtonColor.popupBackgroundColor
            maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else if keyboardIdiom.isPad, case .returnKey(let type) = keyCap, type != .confirm {
            let buttonImage = adjustImageFontSize(ButtonImage.returnKey)
            setImage(buttonImage, for: .normal)
            setImage(buttonImage, for: .highlighted)
            imageView?.contentMode = .scaleAspectFit
            setHighlightedBackground = true
        } else if let buttonText = keyCap.unescaped.buttonText {
            setTitle(buttonText, for: .normal)
            if keyboardState.inputMode != .english,
               case .keyboardType(.alphabetic) = keyCap {
                setTitle(keyboardState.activeSchema.shortName, for: .normal)
            }
            titleLabel?.baselineAdjustment = .alignCenters
            titleLabel?.lineBreakMode = .byClipping
            titleLabel?.adjustsFontSizeToFitWidth = true
            setHighlightedBackground = true
        } else if var buttonImage = keyCap.unescaped.buttonImage {
            if keyCap == .keyboardType(.emojis) && traitCollection.userInterfaceStyle == .dark {
                // Special handling for emoji icon. We use different symbols in light/dark mode.
                buttonImage = adjustImageFontSize(ButtonImage.emojiKeyboardDark)
            } else {
                buttonImage = adjustImageFontSize(buttonImage)
            }
            setImage(buttonImage, for: .normal)
            setImage(keyCap == .backspace ? adjustImageFontSize(ButtonImage.backspaceFilled) : buttonImage, for: .highlighted)
            imageView?.contentMode = .scaleAspectFit
            setHighlightedBackground = true
        }
        
        let keyboardViewLayout = keyboardIdiom.keyboardViewLayout
        if let padSwipeDownKeyCap = keyboardViewLayout.getSwipeDownKeyCap(keyCap: keyCap, keyboardState: keyboardState),
           isKeyEnabled {
            if swipeDownHintLayer == nil {
                let swipeDownHintLayer = KeyHintLayer()
                layer.addSublayer(swipeDownHintLayer)
                self.swipeDownHintLayer = swipeDownHintLayer
            }
            if keyboardViewLayout.isSwipeDownKeyShiftMorphing(keyCap: keyCap) {
                contentEdgeInsets = UIEdgeInsets(top: 4, left: 5, bottom: 6, right: 5)
                titleLabelFontSize *= Self.morphingKeyFontRatio
            }
            swipeDownHintLayer?.string = padSwipeDownKeyCap.buttonText
            swipeDownHintLayer?.fontSize = titleLabelFontSize
            updateColorsAccordingToSwipeDownPercentage()
            contentVerticalAlignment = .bottom
        } else {
            swipeDownHintLayer?.removeFromSuperlayer()
            swipeDownHintLayer = nil
            contentVerticalAlignment = keyboardIdiom.isPadFull &&
                !(keyCap.keyCapType == .input || keyCap.keyCapType == .space) ? .bottom : .center
        }
        
        titleLabel?.font = .systemFont(ofSize: titleLabelFontSize * (1 - swipeDownPercentage * 2))
        highlightedColor = setHighlightedBackground ? keyCap.buttonBgHighlightedColor : nil
        highlightedShadowColor = setHighlightedBackground ? keyCap.buttonBgHighlightedShadowColor : nil
        setupKeyHint(keyCap, buttonHintTitle, keyCap.buttonHintFgColor)
        
        layer.maskedCorners = maskedCorners
        layer.shadowOpacity = shadowOpacity
        
        isEnabled = !keyCap.isPlaceholder
        
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
            if !isEnabled || window == nil { return false }
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
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        if let keyHintLayer = keyHintLayer {
            keyHintLayer.isHidden = popupView != nil
            layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.topRightInsets)
        }
        
        if let swipeDownHintLayer = swipeDownHintLayer {
            if let keyboardState = keyboardState,
               keyboardState.keyboardIdiom.keyboardViewLayout.isSwipeDownKeyShiftMorphing(keyCap: keyCap) {
                let yOffset = (1 - swipeDownPercentage) * contentEdgeInsets.top + swipeDownPercentage * bounds.height / 4
                layout(textLayer: swipeDownHintLayer, centeredWithYOffset: yOffset)
            } else {
                let swipeDownHintLayerHeight = (0.3 + swipeDownPercentage * 0.2) * bounds.height
                
                let fullySwipedDownYOffset = (bounds.height - swipeDownHintLayerHeight) / 2
                let yOffset = (1 - swipeDownPercentage) * contentEdgeInsets.top + swipeDownPercentage * fullySwipedDownYOffset
                
                layout(textLayer: swipeDownHintLayer, centeredWithYOffset: yOffset, height: swipeDownHintLayerHeight)
            }
        }
        
        super.layoutSubviews()
        layoutPopupView()
    }
    
    override func display(_ layer: CALayer) {
        if firstFrame {
            firstFrame = false
            return
        }
        guard let layer = layer.presentation() as? SwipeDownLayer else { return }
        swipeDownPercentage = layer.swipeDownPercentage
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        isHighlighted = !flag
        isGrayed = false
    }
    
    private func updateColorsAccordingToSwipeDownPercentage() {
        guard let keyboardIdiom = keyboardState?.keyboardIdiom,
              keyboardIdiom != .phone else { return }
        
        titleLabel?.font = .systemFont(ofSize: titleLabelFontSize * (1 - swipeDownPercentage * 2))
        
        if let mainTextColor = titleColor(for: .normal)?.resolvedColor(with: traitCollection) {
            setTitleColor(mainTextColor.withAlphaComponent(mainTextColor.alpha * (1 - swipeDownPercentage * 4)), for: .highlighted)
            
            if let swipeDownHintLayer = swipeDownHintLayer {
                let isSwipeDownKeyShiftMorphing = keyboardIdiom.keyboardViewLayout.isSwipeDownKeyShiftMorphing(keyCap: keyCap)
                let swipeDownKeyCapTextColor = (isSwipeDownKeyShiftMorphing ? UIColor.label : UIColor.systemGray).resolvedColor(with: traitCollection).cgColor
                swipeDownHintLayer.foregroundColor = swipeDownKeyCapTextColor.interpolate(mainTextColor.cgColor, fraction: swipeDownPercentage * 3)
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
    
    private func adjustImageFontSize(_ image: UIImage) -> UIImage {
        image.withConfiguration(UIImage.SymbolConfiguration(pointSize: titleLabelFontSize))
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
        layer.removeAllAnimations()
        
        touchBeginPosition = touch.location(in: self)
        shouldAcceptLongPress = true
    }
    
    func keyTouchMoved(_ touch: UITouch) {
        guard let keyboardState = keyboardState else { return }
        let keyboardIdiom = keyboardState.keyboardIdiom
        
        if let padSwipeDownKeyCap = keyboardIdiom.keyboardViewLayout.getSwipeDownKeyCap(keyCap: keyCap, keyboardState: keyboardState),
           let touchBeginPosition = touchBeginPosition {
            // Handle iPad swipe down.
            let point = touch.location(in: self)
            let delta = point - touchBeginPosition
            
            swipeDownPercentage = min(max(0, delta.y / bounds.height / Self.swipeDownFullYRatio), 1)
            
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
        touchBeginPosition = nil
        
        if swipeDownPercentage == 0 {
            isHighlighted = false
        } else {
            isGrayed = true
            firstFrame = true
            let layer = layer as! SwipeDownLayer
            let animation = CABasicAnimation(keyPath: #keyPath(SwipeDownLayer.swipeDownPercentage))
            animation.fromValue = swipeDownPercentage
            animation.toValue = 0
            animation.duration = 0.2
            animation.delegate = self
            layer.add(animation, forKey: animation.keyPath)
        }
        
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
        guard let keyboardState = keyboardState else { return }
        let keyboardIdiom = keyboardState.keyboardIdiom
        
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

class SwipeDownLayer: CALayer {
    @NSManaged var swipeDownPercentage: CGFloat
    override class func needsDisplay(forKey key: String) -> Bool {
        return key == #keyPath(swipeDownPercentage) || super.needsDisplay(forKey: key)
    }
}
