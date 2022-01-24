//
//  CandidateCell.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit

class CandidateCell: UICollectionViewCell {
    static var reuseId: String = "CandidateCell"
    
    private static let margin = UIEdgeInsets(top: 3, left: 8, bottom: 0, right: 8)
    private static let fontSizePerHeight: CGFloat = 18 / "＠".size(withFont: UIFont.systemFont(ofSize: 20)).height
    
    private static let candidateLabelHeightRatio: CGFloat = 0.6
    private static let candidateCommentHeightRatio: CGFloat = 0.25
    private static let candidateCommentPaddingHeightRatio: CGFloat = 0.05
    
    var showComment: Bool = false
    
    weak var label: UILabel?
    weak var keyHintLayer: KeyHintLayer?
    weak var commentLayer: CATextLayer?
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<CandidateCell>()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func setup(_ text: String, _ comment: String?, showComment: Bool) {
        self.showComment = showComment
        
        if label == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.baselineAdjustment = .alignBaselines
            label.isUserInteractionEnabled = false

            self.contentView.addSubview(label)
            self.label = label
        }
        
        label?.attributedText = text.toHKAttributedString
        
        let keyCap = KeyCap(stringLiteral: text)
        if let hintText = keyCap.barHint {
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
                commentLayer.font = UIFont.systemFont(ofSize: 10 /* ignored */)
            }
            commentLayer?.string = comment
        } else {
            commentLayer?.removeFromSuperlayer()
            commentLayer = nil
        }
        
        layout(bounds)
    }
    
    func free() {
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
        layout(layoutAttributes.bounds)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let keyHintLayer = keyHintLayer else { return }
        layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.topRightInsets)
    }
    
    private func layout(_ bounds: CGRect) {
        guard let label = label else { return }
        
        let margin = Self.margin
        let availableHeight = bounds.height - margin.top - margin.bottom
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = availableHeight * Self.candidateLabelHeightRatio
        let candidateFontSize = candidateLabelHeight * Self.fontSizePerHeight
        
        label.font = .systemFont(ofSize: candidateFontSize * fontSizeScale)
        
        if showComment, let commentLayer = commentLayer {
            let candidateCommentHeight = availableHeight * Self.candidateCommentHeightRatio
            let candidateCommentFontSize = candidateCommentHeight * Self.fontSizePerHeight
            let commentTopPadding = availableHeight * Self.candidateCommentPaddingHeightRatio
            
            commentLayer.fontSize = candidateCommentFontSize
            
            let textFrame = CGRect(x: 0, y: margin.top, width: bounds.width, height: candidateLabelHeight)
            
            label.frame = textFrame
            
            commentLayer.frame = CGRect(x: 0, y: textFrame.maxY + commentTopPadding, width: bounds.width, height: candidateCommentHeight)
        } else {
            label.frame = bounds
        }
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
    
    static func computeCellSize(cellHeight: CGFloat, minWidth: CGFloat, candidateText: String, comment: String?) -> CGSize {
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = cellHeight * Self.candidateLabelHeightRatio
        let candidateFontSize = candidateLabelHeight * Self.fontSizePerHeight * fontSizeScale
        
        var cellWidth = candidateText.size(withFont: UIFont.systemFont(ofSize: candidateFontSize)).width
        
        if let comment = comment {
            let candidateCommentHeight = cellHeight * Self.candidateCommentHeightRatio
            let candidateCommentFontSize = candidateCommentHeight * Self.fontSizePerHeight
            
            let commentWidth = comment.size(withFont: UIFont.systemFont(ofSize: candidateCommentFontSize)).width
            cellWidth = max(cellWidth, commentWidth)
        }
        
        return Self.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight)).with(minWidth: minWidth)
    }
}
