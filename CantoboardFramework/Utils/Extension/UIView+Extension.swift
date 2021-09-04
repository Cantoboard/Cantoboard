//
//  UIView+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/27/21.
//

import Foundation
import UIKit

internal extension UIView {
    func layout(textLayer: CATextLayer, atTopRightCornerWithInsets insets: UIEdgeInsets) {
        guard !textLayer.isHidden,
              let text = textLayer.string as? String,
              let superlayerBounds = textLayer.superlayer?.bounds
            else { return }
        
        // let wightAdjustmentRatio: CGFloat = UIScreen.main.bounds.size.isPortrait && bounds ? 1 : 1.25
        var height = superlayerBounds.height * KeyHintLayer.recommendedHeightRatio // * wightAdjustmentRatio
        let minHeight: CGFloat = 10
        height = max(height, minHeight)
        
        textLayer.fontSize = KeyHintLayer.fontSizePerHeight * height
        
        let size = text.size(withFont: UIFont.systemFont(ofSize: textLayer.fontSize))
        
        textLayer.frame = CGRect(origin: CGPoint(x: superlayerBounds.width - size.width - insets.right, y: insets.top), size: size)
    }
}
