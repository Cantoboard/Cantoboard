//
//  InstanceCounter.swift
//  CantoboardFramework
//
//  Created by Alex Man on 5/2/21.
//

import Foundation

import CocoaLumberjackSwift

/// Hashable wrapper for any metatype value.
struct AnyHashableMetatype : Hashable {

  static func ==(lhs: AnyHashableMetatype, rhs: AnyHashableMetatype) -> Bool {
    return lhs.base == rhs.base
  }

  let base: Any.Type

  init(_ base: Any.Type) {
    self.base = base
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(base))
  }
  // Pre Swift 4.2:
  // var hashValue: Int { return ObjectIdentifier(base).hashValue }
}

fileprivate var instanceCounts = [AnyHashableMetatype: Int]()

class InstanceCounter<Type> {
    init() {
        DDLogInfo("LEAK DETECTOR \(Type.self) init \(mutate(1))")
    }
    
    deinit {
        DDLogInfo("LEAK DETECTOR \(Type.self) deinit \(mutate(-1))")
    }
    
    private func mutate(_ delta: Int) -> Int {
        let key = AnyHashableMetatype(Type.self)
        let newCount = instanceCounts[key, default: 0] + delta
        instanceCounts.updateValue(newCount, forKey: key)
        return newCount
    }
}
