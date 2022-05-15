//
//  CandidateCell.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit
import CocoaLumberjackSwift

class CandidateCell: UICollectionViewCell {
    static var reuseId: String = "CandidateCell"
    
    private static let margin = UIEdgeInsets(top: 3, left: 8, bottom: 0, right: 8)
    private static let fontSizePerHeight: CGFloat = 18 / "＠".size(withFont: UIFont.systemFont(ofSize: 20)).height
    
    private static let candidateLabelHeightRatio: CGFloat = 0.6
    private static let candidateCommentHeightRatio: CGFloat = 0.25
    private static let candidateCommentPaddingHeightRatio: CGFloat = 0.05
    
    var showComment: Bool = false
    var isFilterCell: Bool = false
    override var isSelected: Bool {
        didSet {
            if isSelected {
                if selectedRectLayer == nil {
                    let selectedRectLayer = CALayer()
                    selectedRectLayer.backgroundColor = ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
                    selectedRectLayer.cornerRadius = 5
                    selectedRectLayer.zPosition = -1
                    layer.addSublayer(selectedRectLayer)
                    self.selectedRectLayer = selectedRectLayer
                    setNeedsLayout()
                }
            } else {
                selectedRectLayer?.removeFromSuperlayer()
                selectedRectLayer = nil
            }
        }
    }
    
    weak var label: UILabel?
    weak var keyHintLayer: KeyHintLayer?
    weak var commentLayer: CATextLayer?
    weak var selectedRectLayer: CALayer?
    
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
        
        selectedRectLayer?.removeFromSuperlayer()
        selectedRectLayer = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layout(layoutAttributes.bounds)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let selectedRectLayer = selectedRectLayer {
            selectedRectLayer.frame = bounds.insetBy(dx: 4, dy: 4)
        }
        
        guard let keyHintLayer = keyHintLayer else { return }
        layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.hintInsets)
    }
    
    private func layout(_ bounds: CGRect) {
        guard let label = label else { return }
        
        let margin = Self.margin
        let availableHeight = bounds.height - margin.top - margin.bottom
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = availableHeight * (isFilterCell ? 0.7 : Self.candidateLabelHeightRatio)
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
        
        keyHintLayer?.foregroundColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
        commentLayer?.foregroundColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
        selectedRectLayer?.backgroundColor = ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
    }
    
    private static var unitFontWidthCache: [CGFloat:(halfWidths: [CGFloat], fullWidth: CGFloat)] = [:]
    
    static func computeCellSize(cellHeight: CGFloat, minWidth: CGFloat, candidateText: String, comment: String?) -> CGSize {
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = cellHeight * Self.candidateLabelHeightRatio
        let candidateFontSizeUnrounded = candidateLabelHeight * Self.fontSizePerHeight * fontSizeScale
        let candidateFontSize = candidateFontSizeUnrounded.roundTo(q: 4)
        
        var cellWidth = estimateStringWidth(candidateText, ofSize: candidateFontSize)
        
        if let comment = comment {
            let candidateCommentHeight = cellHeight * Self.candidateCommentHeightRatio
            let candidateCommentFontSizeUnrounded = candidateCommentHeight * Self.fontSizePerHeight
            let candidateCommentFontSize = candidateCommentFontSizeUnrounded.roundTo(q: 4)
            
            let commentWidth = estimateStringWidth(comment, ofSize: candidateCommentFontSize)
            cellWidth = max(cellWidth, commentWidth)
        }
        
        return Self.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight)).with(minWidth: minWidth)
    }
    
    static func estimateStringWidth(_ s: String, ofSize fontSize: CGFloat) -> CGFloat {
        var unitWidth = unitFontWidthCache[fontSize]
        if unitWidth == nil {
            var halfWidths = Array(repeating: CGFloat.zero, count: 256)
            for b in UInt8.min...UInt8.max {
                let c = Character(UnicodeScalar(b))
                halfWidths[Int(b)] = String(c).size(withFont: UIFont.systemFont(ofSize: fontSize)).width
            }
            let fullWidth = "　".size(withFont: UIFont.systemFont(ofSize: fontSize)).width
            unitWidth = (halfWidths: halfWidths, fullWidth: fullWidth)
            unitFontWidthCache[fontSize] = unitWidth
        }
        
        let estimate = s.reduce(CGFloat.zero, { r, c in
            if c.isASCII {
                return r + unitWidth!.halfWidths[Int(c.asciiValue!)]
            } else {
                return r + unitWidth!.fullWidth
            }
        })

        return estimate
    }
}
