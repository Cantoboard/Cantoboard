//
//  KeyPopupView.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/1/21.
//

import Foundation
import UIKit

class KeyPopupView: UIView {
    static let Inset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    static let LinkHeight = CGFloat(15)
    
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
    private var highlightedLabelIndex: Int?
    
    var selectedAction: KeyboardAction {
        actions[safe: highlightedLabelIndex ?? 0] ?? .none
    }
    
    var heightClearance: CGFloat?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ButtonColor.PopupBackgroundColor // ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).
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
        label.textColor = ButtonColor.KeyForegroundColor
        label.textAlignment = .center
        label.baselineAdjustment = .alignCenters
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
            label.text = keyCap.buttonText
            label.font = keyCap.popupFont
            label.baselineAdjustment = .alignCenters
            label.tag = i
            label.backgroundColor = .clear
            
            if let hint = keyCaps[i].buttonHint {
                let hintLayer = KeyHintLayer()
                hintLayer.setup(keyCap, hint)
                hintLayers.append(hintLayer)
                label.layer.addSublayer(hintLayer)
            }
        }
    }
    
    func setup(keyCaps: [KeyCap], direction: PopupDirection = .middle) {
        self.keyCaps = keyCaps
        self.actions = keyCaps.map { $0.getAction() }
        self.direction = direction
        
        setupLabels(actions)
        //setupBoundaryPath(keyWidthA: keyWidth, direction: direction)
        
        if actions.count > 1 {
            highlightedLabelIndex = 0
            labels[0].backgroundColor = .systemBlue
        }
        
        layoutView()
    }
    
    override func layoutSubviews() {
        layoutView()
    }
    
    func layoutView() {
        var buttonSize = CGSize(
            width: KeyPopupView.Inset.wrapWidth(width: LayoutConstants.forMainScreen.keyButtonWidth),
            height: LayoutConstants.forMainScreen.keyHeight)
        
        
        var bodySize = KeyPopupView.Inset.wrap(size: buttonSize.multiplyWidth(byTimes: max(actions.count, 1)))
        var contentSize = bodySize.extend(height: KeyPopupView.LinkHeight)
        
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
            let x: CGFloat
            switch direction {
            case .right, .middle:
                x = KeyPopupView.Inset.left + buttonSize.width * CGFloat(i)
            case .left, .middleExtendLeft:
                x = KeyPopupView.Inset.left + buttonSize.width * CGFloat(actions.count - 1 - i)
            }
            
            label.frame = CGRect(origin: CGPoint(x: x, y: KeyPopupView.Inset.top), size: buttonSize)
        }
        hintLayers.forEach { $0.layout() }
    }
    
    private func layoutPopupShape(buttonSize: CGSize, bodySize: CGSize, contentSize: CGSize) {
        guard let superview = superview else { return }
        
        bounds = CGRect(origin: CGPoint.zero, size: contentSize)
        
        let keyWidth = superview.bounds.width
        
        let fullSize = contentSize
        let offsetX = (KeyPopupView.Inset.wrap(size: buttonSize).width - keyWidth) / 2
        
        let path = CGMutablePath()
        let bodyRect = CGRect(origin: CGPoint.zero, size: bodySize)
        
        let anchorLeft, anchorRight, neckLeft, neckRight: CGPoint
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
        case .middle:
            anchorLeft = CGPoint(x: offsetX, y: fullSize.height)
            anchorRight = CGPoint(x: offsetX + keyWidth, y: fullSize.height)
            neckLeft = CGPoint(x: 0, y: bodySize.height - 5)
            neckRight = CGPoint(x: anchorRight.x + offsetX, y: bodySize.height - 5)
        case .middleExtendLeft:
            anchorLeft = CGPoint(x: fullSize.width - keyWidth - offsetX, y: fullSize.height)
            anchorRight = CGPoint(x: fullSize.width - offsetX, y: fullSize.height)
            neckLeft = CGPoint(x: anchorLeft.x - offsetX, y: bodySize.height - 5)
            neckRight = CGPoint(x: fullSize.width, y: bodySize.height - 5)
        }
        leftAnchorX = anchorLeft.x
        
        path.addRoundedRect(in: bodyRect, cornerWidth: 5, cornerHeight: 5)
        
        path.move(to: anchorLeft)
        let yVector = CGPoint(x: 0, y: KeyPopupView.LinkHeight / 2)
        path.addCurve(to: neckLeft, control1: anchorLeft - yVector, control2: neckLeft + yVector)
        path.addLine(to: neckRight)
        path.addCurve(to: anchorRight, control1: neckRight + yVector, control2: anchorRight - yVector)
        
        path.closeSubpath()
        
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
            let isLabelSelected: Bool
            switch direction {
            case .left, .middleExtendLeft:
                isLabelSelected = (i == 0 || point.x <= label.frame.maxX) && (i == labels.count - 1 || label.frame.minX <= point.x)
            case .right, .middle:
                isLabelSelected = (i == 0 || label.frame.minX <= point.x) && (i == labels.count - 1 || point.x <= label.frame.maxX)
            }
            
            if isLabelSelected {
                label.backgroundColor = .systemBlue
                highlightedLabelIndex = label.tag
            } else {
                label.backgroundColor = .clear
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        shapeLayer.backgroundColor = ButtonColor.InputKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
        hintLayers.forEach { $0.foregroundColor = ButtonColor.KeyForegroundColor.resolvedColor(with: traitCollection).cgColor }
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
}
