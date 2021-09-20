//
//  MutableReference.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/26/21.
//

import Foundation

class Reference<Type> {
    var ref: Type

    init(_ object: Type) {
        self.ref = object
    }
}
