//
//  CGColor+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 9/11/21.
//

import Foundation
import UIKit

extension CGColor {
    var toRgb: CGColor {
        return converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)!
    }
    
    func interpolate(_ end: CGColor, fraction: CGFloat) -> CGColor {
        let f = min(max(0, fraction), 1)

        guard let c1 = self.toRgb.components, let c2 = end.toRgb.components else { return fraction > 0.5 ? end : self }

        let r: CGFloat = CGFloat(c1[0] + (c2[0] - c1[0]) * f)
        let g: CGFloat = CGFloat(c1[1] + (c2[1] - c1[1]) * f)
        let b: CGFloat = CGFloat(c1[2] + (c2[2] - c1[2]) * f)
        let a: CGFloat = CGFloat(c1[3] + (c2[3] - c1[3]) * f)

        return CGColor(red: r, green: g, blue: b, alpha: a)
    }
}
