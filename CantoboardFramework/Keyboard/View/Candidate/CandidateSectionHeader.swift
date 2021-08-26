//
//  CandidateSectionHeader.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit

class CandidateSectionHeader: UICollectionReusableView {
    static var reuseId: String = "CandidateSectionHeader"
    weak var textLayer: UILabel?
    
    var layoutConstants: LayoutConstants {
        get {
            LayoutConstants.forMainScreen
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = ButtonColor.systemKeyBackgroundColor
    }
    
    func setup(_ text: String, autoSize: Bool) {
        if textLayer == nil {
            let textLayer = UILabel()
            self.textLayer = textLayer
            addSubview(textLayer)
            textLayer.textAlignment = .center
            textLayer.baselineAdjustment = .alignCenters
            textLayer.adjustsFontSizeToFitWidth = autoSize
            textLayer.font = UIFont.systemFont(ofSize: autoSize ? UIFont.labelFontSize : layoutConstants.candidateFontSize + 2)
        }
        
        textLayer?.text = text
        
        layout(bounds)
    }
    
    func free() {
        textLayer?.removeFromSuperview()
        textLayer = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layout(layoutAttributes.bounds)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout(bounds)
    }
    
    private func layout(_ bounds: CGRect) {
        let size = CGSize(width: bounds.width, height: layoutConstants.autoCompleteBarHeight)
        textLayer?.frame = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 0)
    }
}
