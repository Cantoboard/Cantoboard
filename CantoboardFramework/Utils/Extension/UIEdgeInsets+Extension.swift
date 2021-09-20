//
//  UIEdgeInsets+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation
import UIKit

extension UIEdgeInsets {
    func override(top: CGFloat? = nil, left: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: top == nil ? self.top : top!,
            left: left == nil ? self.left : left!,
            bottom: bottom == nil ? self.bottom : bottom!,
            right: right == nil ? self.right : right!)
    }
    
    func wrap(size: CGSize) -> CGSize {
        return CGSize(width: size.width + left + right, height: size.height + top + bottom)
    }
    
    func wrap(width: CGFloat) -> CGFloat {
        return width + left + right
    }
    
    func wrap(widthOnly: CGSize) -> CGSize {
        return CGSize(width: widthOnly.width + left + right, height: widthOnly.height)
    }
    
    func wrap(height: CGFloat) -> CGFloat {
        return height + top + bottom
    }
}
