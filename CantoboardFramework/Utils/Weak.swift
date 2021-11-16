//
//  Weak.swift
//  CantoboardFramework
//
//  Created by Alex Man on 11/15/21.
//

import Foundation

class Weak<Type: AnyObject> {
    weak var ref: Type?

    init(_ object: Type) {
        self.ref = object
    }
}
