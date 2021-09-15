//
//  CGSize+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation
import UIKit

extension CGSize {
    func extend(margin: UIEdgeInsets) -> CGSize {
        return CGSize(width: width + margin.left + margin.right, height: height + margin.top + margin.bottom)
    }
    
    func extend(width: CGFloat? = nil, height: CGFloat? = nil) -> CGSize {
        return CGSize(width: self.width + (width ?? 0), height: self.height + (height ?? 0))
    }
    
    func multiplyWidth(byTimes: Int) -> CGSize {
        return CGSize(width: width * CGFloat(byTimes), height: height)
    }
    
    func with(minWidth: CGFloat) -> CGSize {
        return CGSize(width: max(width, minWidth), height: height)
    }
    
    var isPortrait: Bool {
        height > width
    }
    
    var minDimension: CGFloat {
        return min(width, height)
    }
    
    var asPortrait: CGSize {
        return CGSize(width: min(width, height), height: max(width, height))
    }
    
    var asLandscape: CGSize {
        return CGSize(width: max(width, height), height: min(width, height))
    }
}
