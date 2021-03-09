//
//  RimeApi.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/19/21.
//

import Foundation

// Make RimeApi a singleton with listener.
extension RimeApi {
    private static var _shared: RimeApi?
    private static var listener = RimeApiListener()
    static var stateChangeCallbacks: [RimeApiListener.StateChangeBlock] {
        get { listener.stateChangeCallbacks }
        set { listener.stateChangeCallbacks = newValue }
    }
    
    static var shared: RimeApi {
        if _shared == nil {
            atexit {
                RimeApi._shared = nil
            }
            _shared = RimeApi(bundle: Bundle(for: RimeApi.self))
        }
        return _shared!
    }
    
    static func closeShared() {
        NSLog("Deinitializing RimeApi.")
        RimeApi._shared = nil
    }
}

// Proivde an app level initializer.
extension RimeApi {
    convenience init(bundle: Bundle) {
        guard let resourcePath = bundle.resourcePath else {
            fatalError("Bundle.main.resourcePath is nil.")
        }
        let schemaPath = resourcePath + "/RimeSchema"
        
        let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let userDataPath = documentsDirectory.appendingPathComponent("RimeUserData", isDirectory: true).path
        
        if !FileManager.default.fileExists(atPath: userDataPath) {
            try! FileManager.default.createDirectory(atPath: userDataPath, withIntermediateDirectories: false)
        }
        
        NSLog("Shared data path: %@ User data path: %@", schemaPath, userDataPath)
        
        self.init(RimeApi.listener, sharedDataPath: schemaPath, userDataPath: userDataPath)
    }
}

extension RimeApiState {
    public var debugDescription: String {
        description
    }
    
    public var description: String {
        switch self {
        case .uninitialized: return "uninitialized"
        case .deploying: return "deploying"
        case .failure: return "failure"
        case .succeeded: return "succeeded"
        @unknown default: return "unknown"
        }
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ state: RimeApiState) {
        appendLiteral("\(state.description)")
    }
}
