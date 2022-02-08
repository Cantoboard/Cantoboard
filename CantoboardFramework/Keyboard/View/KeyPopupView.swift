//
//  KeyPopupView.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/1/21.
//

import Foundation
import UIKit

class KeyPopupView: UIView {
    private static let keyHintInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0.75)
    private static let bodyInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    static let phoneLinkHeight: CGFloat = 15, padGapHeight: CGFloat = 5
    
    enum PopupDirection {
        case left
        case middle
        case right
        case middleExtendLeft
    }
    
    private(set) var keyCaps: [KeyCap] = []
    private var actions: [KeyboardAction] = []
    private var shapeLayer: CAShapeLayer!
    private var keyWidth: CGFloat = 0
    private var direction: PopupDirection = .middle
    private var labels: [UILabel] = []
    private var hintLayers: [KeyHintLayer] = []
    private var collectionView: UICollectionView?
    private(set) var leftAnchorX: CGFloat = 0
    private var defaultKeyCapIndex = 0
    private var highlightedLabelIndex: Int?
    private var layoutConstants: Reference<LayoutConstants>
    
    var selectedAction: KeyboardAction {
        actions[safe: highlightedLabelIndex ?? 0] ?? .none
    }
    
    // These clearance values are used to keep the popup view within keyboard view boundary.
    var heightClearance: CGFloat?
    
    init(layoutConstants: Reference<LayoutConstants>) {
        self.layoutConstants = layoutConstants
        
        super.init(frame: .zero)
        
        backgroundColor = ButtonColor.popupBackgroundColor // ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).
        layer.contentsFormat = .gray8Uint

        shapeLayer = CAShapeLayer()
        shapeLayer.contentsFormat = .gray8Uint
        layer.mask = shapeLayer
    }
    
    private func createLabel() -> UILabel {
        let label = UILabel()
        label.layer.contentsFormat = .gray8Uint
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.textColor = ButtonColor.keyForegroundColor
        label.textAlignment = .center
        label.baselineAdjustment = .alignCenters
        label.lineBreakMode = .byClipping
        label.adjustsFontSizeToFitWidth = true

        label.font = .preferredFont(forTextStyle: .title2)
        return label
    }
    
    private func setupLabels(_ actions: [KeyboardAction]) {
        while labels.count < actions.count {
            let label = createLabel()
            labels.append(label)
            addSubview(label)
        }
        
        while labels.count > actions.count {
            labels.remove(at: labels.count - 1).removeFromSuperview()
        }
        
        hintLayers.forEach { $0.removeFromSuperlayer() }
        hintLayers = []
        
        for i in 0..<actions.count {
            let label = labels[i]
            let keyCap = keyCaps[i]
            label.tag = i
            label.text = keyCap.buttonText
            label.baselineAdjustment = .alignCenters
            label.backgroundColor = .clear
            
            if let hint = keyCaps[i].buttonRightHint {
                let hintLayer = KeyHintLayer()
                hintLayer.setup(keyCap: keyCap, hintText: hint)
                hintLayers.append(hintLayer)
                label.layer.addSublayer(hintLayer)
            }
        }
    }
    
    private var linkHeight: CGFloat {
        layoutConstants.ref.idiom.isPad ? Self.padGapHeight : Self.phoneLinkHeight
    }
    
    func setup(keyCaps: [KeyCap], defaultKeyCapIndex: Int, direction: PopupDirection = .middle) {
        self.direction = direction

        if direction == .right || direction == .middle {
            self.keyCaps = keyCaps
            self.defaultKeyCapIndex = defaultKeyCapIndex
        } else {
            self.keyCaps = keyCaps.reversed()
            self.defaultKeyCapIndex = keyCaps.count - 1 - defaultKeyCapIndex
        }
        self.actions = self.keyCaps.map { $0.action }
        
        setupLabels(actions)
        
        if actions.count > 1 {
            highlightedLabelIndex = self.defaultKeyCapIndex
            labels[self.defaultKeyCapIndex].backgroundColor = .systemBlue
        }
        
        hintLayers.forEach { $0.foregroundColor = ButtonColor.keyForegroundColor.resolvedColor(with: traitCollection).cgColor }
    }
    
    override func layoutSubviews() {
        layoutView()
    }
    
    func layoutView() {
        guard let parentKeyView = superview else { return }
        
        let layoutConstants = layoutConstants.ref
        let keyWidth = parentKeyView.bounds.width
        let keyHeight = parentKeyView.bounds.height
        let keyboardWidth = layoutConstants.keyboardWidth
        
        var buttonSize: CGSize
        if actions.count < 10 {
            buttonSize = CGSize(
                width: layoutConstants.idiom.isPad ? keyWidth : KeyPopupView.bodyInsets.wrap(width: keyWidth),
                height: keyHeight)
        } else {
            buttonSize = CGSize(
                width: layoutConstants.idiom.isPad ? keyWidth : keyboardWidth / CGFloat(actions.count),
                height: keyHeight)
        }
        
        var bodySize = KeyPopupView.bodyInsets.wrap(size: buttonSize.multiplyWidth(byTimes: max(actions.count, 1)))
        var contentSize = bodySize.extend(height: linkHeight)
        
        if let heightClearance = heightClearance, contentSize.height > heightClearance {
            let ratio = heightClearance / contentSize.height
            buttonSize.height *= ratio
            bodySize.height *= ratio
            contentSize.height = heightClearance
        }
        
        layoutLabels(buttonSize: buttonSize)
        layoutPopupShape(buttonSize: buttonSize, bodySize: bodySize, contentSize: contentSize)
    }
    
    private func layoutLabels(buttonSize: CGSize) {
        for i in 0..<actions.count {
            let label = labels[i]
            let x = KeyPopupView.bodyInsets.left + buttonSize.width * CGFloat(i)
            
            label.frame = CGRect(origin: CGPoint(x: x, y: KeyPopupView.bodyInsets.top), size: buttonSize)
        }
        hintLayers.forEach {
            layout(textLayer: $0, atTopRightCornerWithInsets: Self.keyHintInsets)
        }
    }
    
    private func layoutPopupShape(buttonSize: CGSize, bodySize: CGSize, contentSize: CGSize) {
        guard let superview = superview else { return }
        
        bounds = CGRect(origin: CGPoint.zero, size: contentSize)
        
        let keyWidth = superview.bounds.width
        
        let fullSize = contentSize
        let offsetX = (KeyPopupView.bodyInsets.wrap(size: buttonSize).width - keyWidth) / 2
        
        let path = CGMutablePath()
        let bodyRect = CGRect(origin: CGPoint.zero, size: bodySize)
        
        var anchorLeft, anchorRight, neckLeft, neckRight: CGPoint
        switch direction {
        case .left:
            anchorLeft = CGPoint(x: fullSize.width - keyWidth, y: fullSize.height)
            anchorRight = CGPoint(x: fullSize.width, y: fullSize.height)
            neckLeft = CGPoint(x: anchorLeft.x - 2 * offsetX, y: bodySize.height - 5)
            neckRight = CGPoint(x: fullSize.width, y: bodySize.height - 5)
        case .right:
            anchorLeft = CGPoint(x: 0, y: fullSize.height)
            anchorRight = CGPoint(x: keyWidth, y: fullSize.height)
            neckLeft = CGPoint(x: 0, y: bodySize.height - 5)
            neckRight = CGPoint(x: anchorRight.x + 2 * offsetX, y: bodySize.height - 5)
        default:
            let defaultKeyCapIndex = min(self.defaultKeyCapIndex, keyCaps.count - 1)
            guard defaultKeyCapIndex >= 0 else { return }
            let defaultKeyCapMinX = buttonSize.width * CGFloat(defaultKeyCapIndex)
            let defaultKeyCapMaxX = defaultKeyCapMinX + KeyPopupView.bodyInsets.wrap(width: buttonSize.width)
            neckLeft = CGPoint(x: defaultKeyCapMinX, y: bodySize.height - 5)
            neckRight = CGPoint(x: defaultKeyCapMaxX, y: bodySize.height - 5)
            anchorLeft = CGPoint(x: neckLeft.x + offsetX, y: fullSize.height)
            anchorRight = CGPoint(x: anchorLeft.x + superview.bounds.width, y: fullSize.height)
        }
        
        leftAnchorX = anchorLeft.x
        
        path.addRoundedRect(in: bodyRect, cornerWidth: 5, cornerHeight: 5)
        
        if !layoutConstants.ref.idiom.isPad {
            path.move(to: anchorLeft)
            let yVector = CGPoint(x: 0, y: linkHeight / 2)
            path.addCurve(to: neckLeft, control1: anchorLeft - yVector, control2: neckLeft + yVector)
            path.addLine(to: neckRight)
            path.addCurve(to: anchorRight, control1: neckRight + yVector, control2: anchorRight - yVector)
            
            path.closeSubpath()
        }
        
        shapeLayer.path = path
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Disable touch handling. TouchHandler will handle all the touch events.
        return nil
    }
    
    func updateSelectedAction(_ touch: UITouch) {
        guard labels.count > 1 else { return }
        let point = touch.location(in: self)
        for i in 0..<labels.count {
            let label = labels[i]
            let isLabelSelected = (i == 0 || label.frame.minX <= point.x) && (i == labels.count - 1 || point.x <= label.frame.maxX)
            
            if isLabelSelected {
                label.backgroundColor = .systemBlue
                highlightedLabelIndex = label.tag
            } else {
                label.backgroundColor = .clear
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        shapeLayer.backgroundColor = ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
        hintLayers.forEach { $0.foregroundColor = ButtonColor.keyForegroundColor.resolvedColor(with: traitCollection).cgColor }
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
}
