//
//  CandidateCollectionView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/25/21.
//

import Foundation
import UIKit

class CandidateCell: UICollectionViewCell {
    static var ReuseId: String = "CandidateCell"
    static let FontSize = CGFloat(22)
    static let Font = UIFont.systemFont(ofSize: CandidateCell.FontSize)
    static let UnitCharSize: CGSize = "＠".size(withAttributes: [NSAttributedString.Key.font : Font])
    static let Margin = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    weak var label: UILabel?
    weak var keyHintLayer: KeyHintLayer?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func initLabel(_ text: String) {
        if label == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.baselineAdjustment = .alignBaselines
            label.isUserInteractionEnabled = false
            label.font = CandidateCell.Font

            self.contentView.addSubview(label)
            self.label = label
        }
        
        label?.frame = bounds
        label?.text = text
        
        let keyCap = KeyCap(stringLiteral: text)
        if let hintText = keyCap.buttonHint {
            if keyHintLayer == nil {
                let keyHintLayer = KeyHintLayer()
                self.keyHintLayer = keyHintLayer
                layer.addSublayer(keyHintLayer)
                keyHintLayer.layoutSublayers()
                keyHintLayer.foregroundColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
            }
            
            keyHintLayer?.setup(keyCap: keyCap, hintText: hintText, parentInsets: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
        }
    }
    
    func deinitLabel() {
        label?.text = nil
        label?.removeFromSuperview()
        label = nil
        
        keyHintLayer?.removeFromSuperlayer()
        keyHintLayer = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        self.label?.frame = layoutAttributes.bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        keyHintLayer?.layout()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if let keyHintLayer = keyHintLayer {
            keyHintLayer.foregroundColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
        }
    }
}

class CandidateCollectionView: UICollectionView {
    var scrollOnLayoutSubviews: (() -> Void)?
    var didLayoutSubviews: ((UICollectionView) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollOnLayoutSubviews?()
        scrollOnLayoutSubviews = nil
        
        didLayoutSubviews?(self)
    }
}

protocol CandidatePaneViewDelegate: NSObject {
    func candidatePaneViewExpanded()
    func candidatePaneViewCollapsed()
    func candidatePaneViewCandidateSelected(_ choice: Int)
    func candidatePaneCandidateLoaded()
    func handleKey(_ action: KeyboardAction)
    var symbolShape: SymbolShape { get }
    var symbolShapeOverride: SymbolShape? { get set }
}
