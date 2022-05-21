//
//  StatusButton.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/11/21.
//

import Foundation
import UIKit

extension CALayer {
    static let disableAnimationActions: [String : CAAction] =  [
        "backgroundColor": NSNull(),
        "bounds": NSNull(),
        "contents": NSNull(),
        "fontSize": NSNull(),
        "foregroundColor": NSNull(),
        "hidden": NSNull(),
        "onOrderIn": NSNull(),
        "onOrderOut": NSNull(),
        "position": NSNull(),
        "string": NSNull(),
        "sublayers": NSNull(),
    ]
}

class StatusButton: UIButton {
    private static let longPressDelay: Double = 0.3
    static let statusInset: CGFloat = 4, miniExpandImageInset: CGFloat = 7
    private static let miniExpandImageSizeRatio: CGFloat = 0.18, miniExpandImageAspectRatio: CGFloat = 1 / 2.3
    
    private var longPressTimer: Timer?
    private var isMenuActive: Bool = false
    
    private weak var statusSquareBg: CALayer?
    private weak var miniExpandImageLayer: CALayer?, miniExpandImageMaskLayer: CALayer?
    
    // Touch event near the screen edge are delayed.
    // Overriding preferredScreenEdgesDeferringSystemGestures doesnt work in UIInputViewController,
    // As a workaround we use UILongPressGestureRecognizer to detect taps without delays.
    private weak var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<StatusButton>()
    
    var handleStatusMenu: ((_ from: UIView, _ with: UIEvent?) -> Bool)?
    
    var isMini: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    var shouldShowMenuIndicator: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    var shouldShowStatusBackground: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let statusSquareBg = CALayer()
        statusSquareBg.actions = CALayer.disableAnimationActions
        statusSquareBg.frame = frame.insetBy(dx: Self.statusInset, dy: Self.statusInset)
        statusSquareBg.backgroundColor = ButtonColor.systemKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
        statusSquareBg.cornerRadius = 3
        statusSquareBg.masksToBounds = true
        layer.addSublayer(statusSquareBg)
        
        self.statusSquareBg = statusSquareBg
        
        let longPressGestureRecognizer = BypassScreenEdgeTouchDelayGestureRecognizer(onTouchesBegan: { [weak self] touches, event in
            guard let self = self else { return }
            self.touchesBegan(touches, with: event)
        })
        addGestureRecognizer(longPressGestureRecognizer)
        self.longPressGestureRecognizer = longPressGestureRecognizer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel?.font = .preferredFont(forTextStyle: isMini ? .caption1 : .title2)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.textAlignment = .center
        if !isMini {
            titleLabel?.frame = bounds.insetBy(dx: Self.statusInset, dy: Self.statusInset)
            statusSquareBg?.frame = bounds.insetBy(dx: Self.statusInset, dy: Self.statusInset)
        }
        statusSquareBg?.isHidden = isMini || !shouldShowStatusBackground
        setTitleColor(isMini ? ButtonColor.keyHintColor : .label, for: .normal)
        
        if !isMini && shouldShowMenuIndicator {
            createMiniExpandImageLayer()
            
            let width = bounds.width * Self.miniExpandImageSizeRatio
            let size = CGSize(width: width, height: width * Self.miniExpandImageAspectRatio)
            let origin = CGPoint(x: Self.miniExpandImageInset, y: bounds.maxY - Self.miniExpandImageInset - size.height)
            miniExpandImageLayer?.frame = CGRect(origin: origin, size: size)
            miniExpandImageMaskLayer?.frame = CGRect(origin: .zero, size: size)
        } else {
            miniExpandImageLayer?.removeFromSuperlayer()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        statusSquareBg?.backgroundColor = ButtonColor.systemKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
        miniExpandImageLayer?.backgroundColor = ButtonColor.keyHintColor.resolvedColor(with: traitCollection).cgColor
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        guard isEnabled else { return }
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: Self.longPressDelay, repeats: false) { [weak self] timer in
            guard let self = self, self.shouldShowMenuIndicator && !self.isMenuActive && self.longPressTimer == timer else { return }
            guard self.isEnabled else { return }
            self.isMenuActive = self.handleStatusMenu?(self, event) ?? false
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if !bounds.contains(location) && location.y > bounds.height * 1.5 || isMenuActive {
            isMenuActive = handleStatusMenu?(self, event) ?? false
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        guard let touch = touches.first else { return }
        guard self.isEnabled else {
            super.touchesEnded(touches, with: event)
            return
        }
        let location = touch.location(in: self)
        if bounds.contains(location) && !isMenuActive {
            super.touchesEnded(touches, with: event)
        } else {
            touchesCancelled(touches, with: event)
        }
        if isMenuActive {
            isMenuActive = handleStatusMenu?(self, event) ?? false
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        isMenuActive = handleStatusMenu?(self, event) ?? false
    }
    
    private func createMiniExpandImageLayer() {
        if miniExpandImageLayer == nil {
            let miniExpandImageLayer = CALayer(), miniExpandImageMaskLayer = CALayer()
            miniExpandImageLayer.backgroundColor = ButtonColor.keyForegroundColor.resolvedColor(with: traitCollection).cgColor
            miniExpandImageLayer.mask = miniExpandImageMaskLayer
            miniExpandImageLayer.actions = CALayer.disableAnimationActions
            miniExpandImageMaskLayer.actions = CALayer.disableAnimationActions
            miniExpandImageMaskLayer.contents = ButtonImage.paneExpandButtonImage.cgImage
            
            layer.addSublayer(miniExpandImageLayer)
            self.miniExpandImageLayer = miniExpandImageLayer
            self.miniExpandImageMaskLayer = miniExpandImageMaskLayer
        }
    }
}
