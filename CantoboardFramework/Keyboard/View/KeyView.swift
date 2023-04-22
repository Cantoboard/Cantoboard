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
    private static let morphingSymbolKeyFontRatio = 0.85
    private static let morphingSwipeDownHintLayerMinScale = 0.6
    private static let padTopRowButtonFontSize: CGFloat = 15
    private static let morphingKeyEdgeInsets = UIEdgeInsets(top: 4, left: 5, bottom: 8, right: 5)
    private static let padTopRowButtonEdgeInsets = UIEdgeInsets(top: 3, left: 4, bottom: 5, right: 4)
    
    private var leftKeyHintLayer: KeyHintLayer?
    private var rightKeyHintLayer: KeyHintLayer?
    private var bottomKeyHintLayer: KeyHintLayer?
    private var swipeDownHintLayer: KeyHintLayer?
    private var swipeDownPercentage: CGFloat = 0 {
        didSet {
            setNeedsLayout()
            updateColorsAccordingToSwipeDownPercentage()
        }
    }
    private var titleLabelFontSize: CGFloat = 0
    
    private var popupView: KeyPopupView?
    private var isPopupInLongPressMode: Bool?
    private var touchBeginPosition: CGPoint?
    private var shouldAcceptLongPress: Bool = false
    
    private(set) var keyCap: KeyCap = .none
    private var keyboardState: KeyboardState? = nil
    private var isPadTopRowButton = false
    private var action: KeyboardAction = .none
    private var comboCount: Int = 0
    private var comboTimer: Timer?
    private var inComboMode: Bool = false
    private var lastComboText: String?

    private var layoutConstants: Reference<LayoutConstants>

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
    var shouldDisablePreview: Bool = false
    
    var heightClearance: CGFloat?
    
    // We have to override the title to always render using HK style to center full width symbols.
    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        if state == .normal {
            updateTitle()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            updateTitle()
        }
    }
    
    var titleAlpha: CGFloat = 1 {
        didSet {
            updateTitle()
        }
    }
    
    private func updateTitle() {
        let alphaFromColor = tintColor.resolvedColor(with: traitCollection).alpha
        let enabledAlpha = isEnabled ? 1 : 0.5
        let finalAlpha = enabledAlpha * alphaFromColor * titleAlpha
        let finalColor = tintColor.withAlphaComponent(finalAlpha)
        
        let titleText = title(for: .normal)
        
        let attributedTitleText = titleText?.toHKAttributedString(withForegroundColor: finalColor)
        setAttributedTitle(attributedTitleText, for: .normal)
        
        let originalHintColor = keyCap.buttonHintFgColor.resolvedColor(with: traitCollection).cgColor
        bottomKeyHintLayer?.foregroundColor = originalHintColor.copy(alpha: originalHintColor.alpha * enabledAlpha * titleAlpha)
    }
    
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
            keyboardState?.isPortrait != newState.isPortrait ||
            keyboardState?.isKeyboardAppearing != newState.isKeyboardAppearing ||
            keyboardState?.keyboardType != newState.keyboardType || // Refresh top num key rows on iPad Pro 5 rows layout to hide swipe down key.
            self.isPadTopRowButton != isPadTopRowButton
        guard keyCap != self.keyCap || hasStateChanged else { return }
        
        let shouldDisableCombo = self.keyCap.isCombo != keyCap.isCombo
        self.keyCap = keyCap
        self.action = keyCap.action
        self.selectedAction = keyCap.action
        self.isPadTopRowButton = isPadTopRowButton
        self.keyboardState = newState
        if shouldDisableCombo {
            updateComboMode(enabled: false)
        }
        
        if newState.isKeyboardAppearing {
            swipeDownPercentage = 0
            setupView()
        }
    }
    
    internal func setupView() {
        guard let keyboardState = keyboardState else { return }
        let keyboardIdiom = keyboardState.keyboardIdiom
        
        backgroundColor = keyCap.buttonBgColor
        
        let foregroundColor = keyCap.buttonFgColor
        isEnabled = !keyCap.isPlaceholder
        setTitleColor(foregroundColor, for: .normal)
        setTitleColor(ButtonColor.placeholderKeyForegroundColor, for: .disabled)
        tintColor = foregroundColor
        contentEdgeInsets = layoutConstants.ref.keyViewInsets
        titleEdgeInsets = keyCap.buttonTitleInset
        layer.cornerRadius = layoutConstants.ref.cornerRadius
        titleLabelFontSize = isPadTopRowButton ? Self.padTopRowButtonFontSize : layoutConstants.ref.getButtonFontSize(keyCap.unescaped)
        if keyboardIdiom.isPad && !keyboardState.isPortrait {
            titleLabelFontSize *= Self.padLandscapeFontRatio
        }
        
        var maskedCorners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        var shadowOpacity: Float = 1.0
        var buttonLeftHintTitle = keyCap.buttonLeftHint
        var buttonBottomHintTitle = keyCap.buttonBottomHint
        var buttonRightHintTitle = keyCap.buttonRightHint
        var setHighlightedBackground = false
        
        var normalImage: UIImage?
        var highlightedImage: UIImage?
        var titleText: String?

        if !isKeyEnabled {
            if case .shift = keyCap {
                // Hide the highlighted color in swipe mode.
                backgroundColor = ButtonColor.systemKeyBackgroundColor
            }
            shadowOpacity = 0
            buttonBottomHintTitle = nil
            buttonLeftHintTitle = nil
            buttonRightHintTitle = nil
        } else if popupView != nil && keyboardIdiom == .phone {
            backgroundColor = ButtonColor.popupBackgroundColor
            maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else if keyboardIdiom.isPad, case .returnKey(let type) = keyCap, type != .confirm {
            let buttonImage = ButtonImage.returnKey
            normalImage = buttonImage
            highlightedImage = buttonImage
            //setImage(buttonImage, for: .normal)
            //setImage(buttonImage, for: .highlighted)
            //imageView?.contentMode = .scaleAspectFit
            setHighlightedBackground = true
        } else if let buttonText = keyCap.unescaped.buttonText {
            titleText = buttonText
            if keyboardState.inputMode != .english,
               case .keyboardType(.alphabetic) = keyCap {
                titleText = keyboardState.activeSchema.shortName
            }
            // titleLabel?.baselineAdjustment = .alignCenters
            // titleLabel?.lineBreakMode = .byClipping
            setHighlightedBackground = true
        } else if let buttonImage = keyCap.unescaped.buttonImage {
            if keyCap == .keyboardType(.emojis) && traitCollection.userInterfaceStyle == .dark {
                // Special handling for emoji icon. We use different symbols in light/dark mode.
                normalImage = ButtonImage.emojiKeyboardDark
            } else {
                normalImage = buttonImage
            }
            highlightedImage = keyCap == .backspace ? ButtonImage.backspaceFilled : buttonImage
            // imageView?.contentMode = .scaleAspectFit
            setHighlightedBackground = true
        }
        
        setImage(adjustImageFontSize(normalImage), for: .normal)
        setImage(adjustImageFontSize(highlightedImage), for: .highlighted)
        setTitle(titleText, for: .normal)
        
        let keyboardViewLayout = keyboardIdiom.keyboardViewLayout
        if let padSwipeDownKeyCap = keyboardViewLayout.getSwipeDownKeyCap(keyCap: keyCap, keyboardState: keyboardState),
           isKeyEnabled {
            if swipeDownHintLayer == nil {
                let swipeDownHintLayer = KeyHintLayer()
                layer.addSublayer(swipeDownHintLayer)
                self.swipeDownHintLayer = swipeDownHintLayer
            }
            // Shrink edge insets to avoid swipeDownHintLayer and titleLabel overlapping each other.
            contentEdgeInsets = isPadTopRowButton ? Self.padTopRowButtonEdgeInsets : Self.morphingKeyEdgeInsets
            
            // Scale swipeDownHintLayer by swipeDownPercentage.
            // For shift morphing keys (morphing keys appearing even in autocapped mode), they should appear as large as the main titleLabel.
            // Using morphingKeyFontRatio = 0.9 to shrink the swipe down labels. As keys ,.;' look smaller than their swipe down key counterparts.
            let swipeDownHintLayerMinScale = keyboardViewLayout.isSwipeDownKeyShiftMorphing(keyCap: keyCap) ? Self.morphingKeyFontRatio : Self.morphingSwipeDownHintLayerMinScale
            let swipeDownHintLayerScale = isPadTopRowButton ? 1 : (1 - swipeDownPercentage) * swipeDownHintLayerMinScale + (swipeDownPercentage) * 1
            let swipeDownHintLayerFont = UIFont.systemFont(ofSize: titleLabelFontSize * swipeDownHintLayerScale)
            swipeDownHintLayer?.string = padSwipeDownKeyCap.buttonText?.toHKAttributedString(withFont: swipeDownHintLayerFont)
            updateColorsAccordingToSwipeDownPercentage()
            contentVerticalAlignment = .bottom
        } else {
            titleLabel?.font = .systemFont(ofSize: titleLabelFontSize * (1 - swipeDownPercentage))
            swipeDownHintLayer?.removeFromSuperlayer()
            swipeDownHintLayer = nil
            contentVerticalAlignment = keyboardIdiom.isPadFull &&
                !(keyCap.keyCapType == .input || keyCap.keyCapType == .space) ? .bottom : .center
        }
        
        titleLabel?.adjustsFontSizeToFitWidth = true
        highlightedColor = setHighlightedBackground ? keyCap.buttonBgHighlightedColor : nil
        highlightedShadowColor = setHighlightedBackground ? keyCap.buttonBgHighlightedShadowColor : nil
        
        setupKeyHint(keyCap, buttonLeftHintTitle, keyCap.buttonHintFgColor, keyHintLayer: &leftKeyHintLayer)
        setupKeyHint(keyCap, buttonRightHintTitle, keyCap.buttonHintFgColor, keyHintLayer: &rightKeyHintLayer)
        setupKeyHint(keyCap, buttonBottomHintTitle, keyCap.buttonHintFgColor, keyHintLayer: &bottomKeyHintLayer)
        
        layer.maskedCorners = maskedCorners
        layer.shadowOpacity = shadowOpacity
        
        if let superview = superview { superview.bringSubviewToFront(self) }
        
        // isUserInteractionEnabled = action == .nextKeyboard
        // layoutPopupView()
        setNeedsLayout()
    }
    
    private func setupKeyHint(_ keyCap: KeyCap, _ buttonHintTitle: String?, _ foregroundColor: UIColor, keyHintLayer: inout KeyHintLayer?) {
        if let buttonHintTitle = buttonHintTitle {
            if keyHintLayer == nil {
                let newKeyHintLayer = KeyHintLayer()
                newKeyHintLayer.foregroundColor = keyCap.buttonHintFgColor.resolvedColor(with: traitCollection).cgColor
                keyHintLayer = newKeyHintLayer
                layer.addSublayer(newKeyHintLayer)
                newKeyHintLayer.layoutSublayers()
            }
            keyHintLayer?.setup(keyCap: keyCap, hintText: buttonHintTitle)
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
        
        [leftKeyHintLayer, rightKeyHintLayer, bottomKeyHintLayer].compactMap({ $0 }).forEach { keyHintLayer in
            keyHintLayer.foregroundColor = keyCap.buttonHintFgColor.resolvedColor(with: traitCollection).cgColor
        }
        
        updateColorsAccordingToSwipeDownPercentage()
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        if let keyHintLayer = leftKeyHintLayer {
            keyHintLayer.isHidden = popupView != nil
            layout(textLayer: keyHintLayer, atTopLeftCornerWithInsets: KeyHintLayer.hintInsets)
        }
        
        if let keyHintLayer = rightKeyHintLayer {
            keyHintLayer.isHidden = popupView != nil
            layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.hintInsets)
        }
        
        if let keyHintLayer = bottomKeyHintLayer {
            keyHintLayer.isHidden = popupView != nil
            layout(textLayer: keyHintLayer, atBottomCenterWithInsets: KeyHintLayer.hintInsets)
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
        
        let reverseSwipeDownPercentage = 1 - swipeDownPercentage
        // Fade out original key faster by squaring
        let fontPercentage = pow(reverseSwipeDownPercentage, 2)
        let alphaPercentage = fontPercentage
        titleLabel?.font = .systemFont(ofSize: titleLabelFontSize * fontPercentage)
        
        if let mainTextColor = titleColor(for: .normal)?.resolvedColor(with: traitCollection) {
            titleAlpha = alphaPercentage
            
            if let swipeDownHintLayer = swipeDownHintLayer {
                let isSwipeDownKeyShiftMorphing = keyboardIdiom.keyboardViewLayout.isSwipeDownKeyShiftMorphing(keyCap: keyCap)
                let swipeDownKeyCapTextColor = (isSwipeDownKeyShiftMorphing ? UIColor.label : UIColor.systemGray).resolvedColor(with: traitCollection).cgColor
                let foregroundColor = swipeDownKeyCapTextColor.interpolate(mainTextColor.cgColor, fraction: swipeDownPercentage * 3)
                if let swipeDownHintAttributedString = swipeDownHintLayer.string as? NSAttributedString {
                    let wholeRange = NSMakeRange(0,  swipeDownHintAttributedString.length)
                    let textWithColor = NSMutableAttributedString(attributedString: swipeDownHintAttributedString)
                    textWithColor.addAttribute(.foregroundColor, value: foregroundColor, range: wholeRange)
                    swipeDownHintLayer.string = textWithColor
                }
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
    
    private func adjustImageFontSize(_ image: UIImage?) -> UIImage? {
        let config = UIImage.SymbolConfiguration(
            pointSize: keyboardState?.keyboardIdiom.isPad ?? false ? 24 : 20,
            weight: .light)
        return image?.applyingSymbolConfiguration(config)
    }
    
    func dispatchKeyAction(_ action: KeyboardAction, _ delegate: KeyboardViewDelegate) {
        if case .combo(let items) = keyCap {
            for _ in 0..<(lastComboText?.count ?? 0) {
                delegate.handleKey(.backspace)
            }
            
            if let chosenItem = items[safe: comboCount] {
                delegate.handleKey(.character(chosenItem))
                lastComboText = chosenItem
            }
            
            comboCount = (comboCount + 1) % items.count
            updateComboMode(enabled: true)
        } else {
            delegate.handleKey(action)
        }
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
            isHighlighted = inComboMode
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
            swipeDownPercentage = 0
        }
        
        removePopup()
    }
    
    func keyLongPressed(_ touch: UITouch) {
        guard shouldAcceptLongPress else { return }
        updatePopup(isLongPress: true)
    }
    
    func updateComboMode(enabled: Bool) {
        inComboMode = enabled
        if enabled {
            comboTimer?.invalidate()
            comboTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [self] _ in
                isHighlighted = false
                updateComboMode(enabled: false)
            }
        } else {
            comboTimer?.invalidate()
            comboTimer = nil
            isHighlighted = false
            comboCount = 0
            lastComboText = nil
        }
    }
    
    private func createPopupViewIfNecessary() {
        if popupView == nil {
            let popupView = KeyPopupView(layoutConstants: layoutConstants)
            addSubview(popupView)
            
            self.popupView = popupView
        }
    }
    
    private func updatePopup(isLongPress: Bool) {
        guard let keyboardState = keyboardState else { return }
        let keyboardIdiom = keyboardState.keyboardIdiom
        
        guard keyCap.hasPopup else { return }
        
        // iPad does not have popup preview.
        if keyboardIdiom.isPad && !isLongPress { return }
        
        // Special case, do not show "enhance" keycap of the emoji button.
        if keyCap == .keyboardType(.emojis) && !isLongPress {
            return
        }
        
        let keyCaps = computeKeyCap(isLongPress: isLongPress)
        // On iPad, shows popup only in long press mode and if there are multiple choices.
        let isPadKeyWithoutChildren = keyboardIdiom.isPad && keyCaps.count == 1
        let isPhoneWithPreviewDisabled = !Settings.cached.enableCharPreview && !isLongPress
        // Disable preview in keypad view.
        let isInKeypadView = !isLongPress && shouldDisablePreview
        if isPadKeyWithoutChildren || isPhoneWithPreviewDisabled || isInKeypadView {
            return
        }
        
        createPopupViewIfNecessary()
        guard let popupView = popupView else { return }
        guard isLongPress != isPopupInLongPressMode else { return }
        
        let popupDirection = computePopupDirection()
        
        let defaultChildKeyCapTitle: String?
        let isSwipeDownKeyEnabled = keyCap.buttonLeftHint != nil
        // Disable swipe down priority change for tonal keys and symbol keys but not rev lookup key.
        let hasRightHints = keyCap.buttonRightHint != nil && keyCap.character?.lowercasedChar != "r"
        if isSwipeDownKeyEnabled && !hasRightHints && keyCap != .currency &&
            keyboardState.showCommonSwipeDownKeysInLongPress {
            defaultChildKeyCapTitle = CommonSwipeDownKeys.getSwipeDownKeyCapForPadShortOrFull4Rows(keyCap: keyCap, keyboardState: keyboardState)?.buttonText ?? keyCap.defaultChildKeyCapTitle
        } else {
            defaultChildKeyCapTitle = keyCap.defaultChildKeyCapTitle
        }
        
        let defaultKeyCapIndex: Int
        defaultKeyCapIndex = keyCaps.firstIndex(where: { $0.buttonText == defaultChildKeyCapTitle || $0.isRimeTone }) ?? 0
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
        
        // For tonal input keys, always show popup on the right.
        if keyboardState?.activeSchema.supportCantoneseTonalInput ?? false &&
           Settings.cached.toneInputMode == .longPress,
            case .character(let c, _, _) = keyCap {
            switch c.lowercased() {
            case "f", "g", "h", "c", "v", "b": return .middle
            default: ()
            }
        }
        
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
