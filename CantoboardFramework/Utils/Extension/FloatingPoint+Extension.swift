//
//  FloatingPoint+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 5/14/22.
//

import Foundation

extension FloatingPoint {
    func roundTo(q: Self) -> Self {
        return (self * q).rounded() / q
    }
    
    func clamped(to range: ClosedRange<Self>) -> Self {
        return max(min(self, range.upperBound), range.lowerBound)
    }
}
