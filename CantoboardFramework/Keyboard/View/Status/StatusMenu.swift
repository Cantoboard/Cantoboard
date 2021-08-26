//
//  StatusMenu.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/10/21.
//

import Foundation
import UIKit

class StatusMenu: UIView {
    static let xInset: CGFloat = 5
    static let cornerRadius: CGFloat = 5
    static let separatorWidth: CGFloat = 1
    var labelActions: [UILabel: KeyCap]
    var labels: [[UILabel]]
    var handleKey: ((_ action: KeyboardAction) -> Void)?
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<StatusMenu>()
    
    init(menuRows: [[KeyCap]]) {
        var labelActions: [UILabel: KeyCap] = [:]
        labels = menuRows.map({
            $0.map({ keyCap in
                let label = Self.createLabel(keyCap: keyCap)
                labelActions[label] = keyCap
                return label
            })
        })
        self.labelActions = labelActions
        super.init(frame: .zero)
        
        labels.forEach({ [self] in
            $0.forEach({ self.addSubview($0) })
        })
        backgroundColor = UIColor.tertiarySystemBackground
        layer.cornerRadius = Self.cornerRadius
        
        layer.shadowRadius = 15
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 10, height: 10)
        layer.shadowColor = CGColor(gray: 0, alpha: 1)
        
        labels.first?.first?.layer.maskedCorners = []
        labels.first?.last?.layer.maskedCorners = []
        labels.first?.first?.layer.masksToBounds = true
        labels.first?.last?.layer.masksToBounds = true
        labels.first?.first?.layer.maskedCorners.insert(.layerMinXMinYCorner)
        labels.first?.last?.layer.maskedCorners.insert(.layerMaxXMinYCorner)
        
        labels.last?.first?.layer.maskedCorners = []
        labels.last?.last?.layer.maskedCorners = []
        labels.last?.first?.layer.masksToBounds = true
        labels.last?.last?.layer.masksToBounds = true
        labels.last?.first?.layer.maskedCorners.insert(.layerMinXMaxYCorner)
        labels.last?.last?.layer.maskedCorners.insert(.layerMaxXMaxYCorner)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func createLabel(keyCap: KeyCap) -> UILabel {
        let label = UILabel()
        label.text = keyCap.buttonText
        label.textAlignment = .center
        label.layer.cornerRadius = Self.cornerRadius
        return label
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = CGPath(roundedRect: bounds, cornerWidth: Self.cornerRadius, cornerHeight: Self.cornerRadius, transform: nil)
        
        var y = CGFloat(0)
        for r in 0..<labels.count {
            let row = labels[r]
            let cellSize = CGSize(width: LayoutConstants.statusMenuRowSize.width / CGFloat(row.count), height: LayoutConstants.statusMenuRowSize.height)
            var x = CGFloat(0)
            for i in 0..<row.count {
                let label = labels[r][i]
                label.frame = CGRect(origin: CGPoint(x: x, y: y), size: cellSize)
                x += cellSize.width
            }
            y += cellSize.height
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: LayoutConstants.statusMenuRowSize.width, height: LayoutConstants.statusMenuRowSize.height * CGFloat(labels.count))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        for labelRow in labels {
            for label in labelRow {
                let isTouching = label.frame.contains(touchLocation)
                label.backgroundColor = isTouching ? .systemGray3 : .clearInteractable
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        for labelRow in labels {
            for label in labelRow {
                let isTouching = label.frame.contains(touchLocation)
                if isTouching, let keyCap = labelActions[label] {
                    FeedbackProvider.rigidImpact.impactOccurred()
                    handleKey?(keyCap.action)
                    return
                }
            }
        }
    }
}
