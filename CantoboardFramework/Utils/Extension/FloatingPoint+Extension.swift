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
}
