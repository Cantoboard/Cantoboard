//
//  Array+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/7/21.
//

import Foundation

extension Array {
    func mapToSet<T: Hashable>(_ transform: (Element) -> T) -> Set<T> {
        var result = Set<T>()
        for item in self {
            result.insert(transform(item))
        }
        return result
    }
}
