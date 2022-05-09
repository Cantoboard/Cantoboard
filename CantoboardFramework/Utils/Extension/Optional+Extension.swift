//
//  Optional+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 5/7/22.
//

import Foundation

extension Optional {
    func filter(_ predicate: (Wrapped) throws -> Bool) rethrows -> Optional {
        return try flatMap { try predicate($0) ? self : nil }
    }
}
