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
}
