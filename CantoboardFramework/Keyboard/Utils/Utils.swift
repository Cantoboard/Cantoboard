//
//  Utils.swift
//  Stockboard
//
//  Created by Alex Man on 1/14/21.
//

import Foundation

struct Duplet<A: Hashable, B: Hashable>: Hashable {
    let a: A
    let b: B

    func hash(into hasher: inout Hasher) {
        hasher.combine(a)
        hasher.combine(b)
    }

    init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }
}

func ==<A, B> (lhs: Duplet<A, B>, rhs: Duplet<A, B>) -> Bool {
    return lhs.a == rhs.a && lhs.b == rhs.b
}

typealias IntDuplet = Duplet<Int, Int>
