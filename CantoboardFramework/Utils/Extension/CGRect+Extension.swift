//
//  CGRect+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/24/21.
//

import Foundation
import UIKit

extension CGRect {
    func with(x: CGFloat) -> CGRect {
        return CGRect(x: x, y: minY, width: width, height: height)
    }
    
    func with(width: CGFloat) -> CGRect {
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
}
