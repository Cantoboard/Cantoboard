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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection = previousTraitCollection,
              traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass ||
              traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass else {
                return
        }
        
        // Invalidate layout to resize cells.
        collectionViewLayout.invalidateLayout()
    }
}

class CandidateCell: UICollectionViewCell {
    static var reuseId: String = "CandidateCell"
    static let margin = UIEdgeInsets(top: 3, left: 8, bottom: 0, right: 8)
    
    var showComment: Bool = false
    
    weak var label: UILabel?
    weak var keyHintLayer: KeyHintLayer?
    weak var commentLayer: CATextLayer?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func initLabel(_ text: String, _ comment: String?, showComment: Bool) {
        let layoutConstants = LayoutConstants.forMainScreen
        self.showComment = showComment
        
        if label == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.baselineAdjustment = .alignBaselines
            label.isUserInteractionEnabled = false

            self.contentView.addSubview(label)
            self.label = label
        }
        
        label?.font = UIFont.systemFont(ofSize: layoutConstants.candidateFontSize)
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
        
        if showComment, let comment = comment {
            if commentLayer == nil {
                let commentLayer = CATextLayer()
                self.commentLayer = commentLayer
                layer.addSublayer(commentLayer)
                commentLayer.alignmentMode = .center
                commentLayer.allowsFontSubpixelQuantization = true
                commentLayer.contentsScale = UIScreen.main.scale
                commentLayer.foregroundColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
            }
            commentLayer?.font = UIFont.systemFont(ofSize: layoutConstants.candidateCommentFontSize)
            commentLayer?.fontSize = layoutConstants.candidateCommentFontSize
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
        let layoutConstants = LayoutConstants.forMainScreen

        label?.font = UIFont.systemFont(ofSize: layoutConstants.candidateFontSize)
        commentLayer?.font = UIFont.systemFont(ofSize: layoutConstants.candidateCommentFontSize)
        commentLayer?.fontSize = layoutConstants.candidateCommentFontSize
        
        if showComment {
            let margin = Self.margin
            let textFrame = CGRect(x: 0, y: margin.top, width: bounds.width, height: layoutConstants.candidateCharSize.height)
            
            self.label?.frame = textFrame
            let commentHeight = layoutConstants.candidateCommentCharSize.height
            commentLayer?.frame = CGRect(x: 0, y: bounds.height - commentHeight - margin.bottom, width: bounds.width, height: commentHeight)
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
        if let commentLayer = commentLayer {
            commentLayer.foregroundColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
        }
    }
}
