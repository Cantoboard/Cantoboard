//
//  UIColor+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation
import UIKit

extension UIColor {
    var inverted: UIColor {
        var a: CGFloat = 0.0, r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
        return getRed(&r, green: &g, blue: &b, alpha: &a) ? UIColor(red: 1.0-r, green: 1.0-g, blue: 1.0-b, alpha: a) : .black
    }
    
    var alpha: CGFloat {
        var a: CGFloat = 1
        return getWhite(nil, alpha: &a) ? a : 1
    }
    
    static var clearInteractable: UIColor {
        UIColor(white: 1, alpha: 0.005)
    }
}
