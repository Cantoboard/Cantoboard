//
//  CandidateCollectionView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/25/21.
//

import Foundation
import UIKit

// This is the UICollectionView inside CandidatePaneView.
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

class CandidateCell: UICollectionViewCell {
    static var reuseId: String = "CandidateCell"
    static let mainFontSize = CGFloat(22), commentFontSize = CGFloat(12)
    static let mainFont = UIFont.systemFont(ofSize: CandidateCell.mainFontSize)
    static let commentFont = UIFont.systemFont(ofSize: CandidateCell.commentFontSize)
    static let unitCharSize: CGSize = "＠".size(withAttributes: [NSAttributedString.Key.font : mainFont])
    static let commentUnitHeight = "＠".size(withAttributes: [NSAttributedString.Key.font : commentFont]).height
    static let margin = UIEdgeInsets(top: 3, left: 8, bottom: 0, right: 8)
    
    var showComment: Bool = false
    
    weak var label: UILabel?
    weak var keyHintLayer: KeyHintLayer?
    weak var commentLayer: CATextLayer?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func initLabel(_ text: String, _ comment: String?, showComment: Bool) {
        self.showComment = showComment
        
        if label == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.baselineAdjustment = .alignBaselines
            label.isUserInteractionEnabled = false
            label.font = CandidateCell.mainFont

            self.contentView.addSubview(label)
            self.label = label
        }
        
        //let textFrame = CGRect(x: Self.margin.left, y: Self.margin.top, width: bounds.width, height: Self.unitCharSize.height)
        // label?.frame = textFrame
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
            
            keyHintLayer?.setup(keyCap: keyCap, hintText: hintText)
        }
        
        if Settings.cached.shouldShowRomanization, let comment = comment {
            if commentLayer == nil {
                let commentLayer = CATextLayer()
                self.commentLayer = commentLayer
                layer.addSublayer(commentLayer)
                commentLayer.alignmentMode = .center
                commentLayer.font = Self.commentFont
                commentLayer.fontSize = Self.commentFontSize
                commentLayer.allowsFontSubpixelQuantization = true
                commentLayer.contentsScale = UIScreen.main.scale
                commentLayer.foregroundColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
            }
            //commentLayer?.frame = CGRect(x: Self.margin.left, y: textFrame.maxY, width: bounds.width, height: bounds.height - Self.unitCharSize.height)
            // commentLayer?.frame = CGRect(x: Self.margin.left, y: textFrame.maxY, width: bounds.width, height: bounds.height - Self.unitCharSize.height)
            commentLayer?.string = comment
        } else {
            commentLayer?.removeFromSuperlayer()
            commentLayer = nil
        }
        
        layoutTextLayers(bounds)
    }
    
    func deinitLabel() {
        label?.text = nil
        label?.removeFromSuperview()
        label = nil
        
        keyHintLayer?.removeFromSuperlayer()
        keyHintLayer = nil
        
        commentLayer?.removeFromSuperlayer()
        commentLayer = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layoutTextLayers(layoutAttributes.bounds)
    }
    
    private func layoutTextLayers(_ bounds: CGRect) {
        if showComment {
            let margin = Self.margin
            let textFrame = CGRect(x: 0, y: margin.top, width: bounds.width, height: Self.unitCharSize.height)
            
            self.label?.frame = textFrame
            commentLayer?.frame = CGRect(x: 0, y: bounds.height - Self.commentUnitHeight - margin.bottom, width: bounds.width, height: Self.commentUnitHeight)
        } else {
            self.label?.frame = bounds
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        keyHintLayer?.layout(insets: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if let keyHintLayer = keyHintLayer {
            keyHintLayer.foregroundColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
        }
    }
}
