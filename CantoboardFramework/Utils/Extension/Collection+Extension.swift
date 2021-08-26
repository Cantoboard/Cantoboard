//
//  Collection+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension NSArray {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Int) -> Element? {
        guard 0 <= index && index < count else { return nil }
        return self[index]
    }
}
