//
//  CandidateSectionHeader.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit

class CandidateSectionHeader: UICollectionReusableView {
    static let insets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
    static var reuseId: String = "CandidateSectionHeader"
    
    weak var textLayer: UILabel?
    
    var layoutConstants: Reference<LayoutConstants>?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = ButtonColor.systemKeyBackgroundColor
    }
    
    func setup(_ text: String) {
        if textLayer == nil {
            let textLayer = UILabel()
            self.textLayer = textLayer
            addSubview(textLayer)
            textLayer.textAlignment = .center
            textLayer.baselineAdjustment = .alignCenters
            textLayer.font = .preferredFont(forTextStyle: .title2)
            textLayer.adjustsFontSizeToFitWidth = true
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
        guard let layoutConstants = layoutConstants?.ref else { return }
        let size = CGSize(width: bounds.width, height: layoutConstants.autoCompleteBarHeight)
        textLayer?.frame = CGRect(origin: .zero, size: size).inset(by: Self.insets)
    }
}
