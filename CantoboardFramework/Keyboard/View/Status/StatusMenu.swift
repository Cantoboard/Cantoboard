//
//  StatusMenu.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/10/21.
//

import Foundation
import UIKit

class StatusMenu: UIView {
    private static let labelInset: CGFloat = 2
    
    static let xInset: CGFloat = 5
    static let cornerRadius: CGFloat = 5
    static let separatorWidth: CGFloat = 1
    static let fontSizeAtUnitHeight: CGFloat = 15
    static let unitHeight: CGFloat = 45
    
    var itemActions: [UILabel: KeyCap]
    var itemLabelInRows: [[UILabel]]
    var handleKey: ((_ action: KeyboardAction) -> Void)?
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<StatusMenu>()
    
    init(menuRows: [[KeyCap]]) {
        var labelActions: [UILabel: KeyCap] = [:]
        itemLabelInRows = menuRows.map {
            $0.map {
                let label = Self.createLabel(keyCap: $0)
                labelActions[label] = $0
                return label
            }
        }
        self.itemActions = labelActions
        super.init(frame: .zero)
        
        for labelRow in itemLabelInRows {
            for label in labelRow {
                addSubview(label)
            }
        }
        backgroundColor = UIColor.tertiarySystemBackground
        layer.cornerRadius = Self.cornerRadius
        
        layer.shadowRadius = 15
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 10, height: 10)
        layer.shadowColor = CGColor(gray: 0, alpha: 1)
        
        itemLabelInRows.first?.first?.layer.maskedCorners = []
        itemLabelInRows.first?.last?.layer.maskedCorners = []
        itemLabelInRows.first?.first?.layer.masksToBounds = true
        itemLabelInRows.first?.last?.layer.masksToBounds = true
        itemLabelInRows.first?.first?.layer.maskedCorners.insert(.layerMinXMinYCorner)
        itemLabelInRows.first?.last?.layer.maskedCorners.insert(.layerMaxXMinYCorner)
        
        itemLabelInRows.last?.first?.layer.maskedCorners = []
        itemLabelInRows.last?.last?.layer.maskedCorners = []
        itemLabelInRows.last?.first?.layer.masksToBounds = true
        itemLabelInRows.last?.last?.layer.masksToBounds = true
        itemLabelInRows.last?.first?.layer.maskedCorners.insert(.layerMinXMaxYCorner)
        itemLabelInRows.last?.last?.layer.maskedCorners.insert(.layerMaxXMaxYCorner)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func createLabel(keyCap: KeyCap) -> UILabel {
        let label = UILabel()
        label.text = " \(keyCap.buttonText ?? "") "
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.layer.cornerRadius = Self.cornerRadius
        return label
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = CGPath(roundedRect: bounds, cornerWidth: Self.cornerRadius, cornerHeight: Self.cornerRadius, transform: nil)
        
        var cellSize = CGSize()
        var y = CGFloat(0)
        for labelRow in itemLabelInRows {
            var x = CGFloat(0)
            for label in labelRow {
                cellSize = CGSize(width: bounds.width / CGFloat(labelRow.count), height: bounds.height / CGFloat(itemLabelInRows.count))
                label.frame = CGRect(origin: CGPoint(x: x, y: y), size: cellSize)
                label.font = .systemFont(ofSize: Self.fontSizeAtUnitHeight * (cellSize.height - 2 * Self.labelInset) / Self.unitHeight)
                label.adjustsFontSizeToFitWidth = true
                x += cellSize.width
            }
            y += cellSize.height
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        for labelRow in itemLabelInRows {
            for label in labelRow {
                let isTouching = label.frame.contains(touchLocation)
                label.backgroundColor = isTouching ? .systemBlue : .clearInteractable
                label.textColor = isTouching ? .white : .label
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        for labelRow in itemLabelInRows {
            for label in labelRow {
                let isTouching = label.frame.contains(touchLocation)
                if isTouching, let keyCap = itemActions[label] {
                    FeedbackProvider.rigidImpact.impactOccurred()
                    handleKey?(keyCap.action)
                    return
                }
            }
        }
    }
}
