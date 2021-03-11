//
//  Settings.swift
//  CantoboardFramework
//
//  Created by Alex Man on 2/23/21.
//

import Foundation

public enum ChineseScript: String {
    case traditionalHK = "zh-HK"
    case traditionalTW = "zh-TW"
    case simplified = "zh-CN"
}

public enum SymbolShape: String {
    case half = "half"
    case full = "full"
    case smart = "smart"
}

public enum SpaceOutputMode: String {
    case input = "input"
    case bestCandidate = "bestCandidate"
}

public class Settings {
    private var userDefaults: UserDefaults
    private let chineseScriptKeyName = "chineseScript"
    private let enableEnglishInputKeyName = "enableEnglish"
    private let symbolShapeKeyName = "symbolShape"
    private let spaceOutputModeKeyName = "spaceOutputMode"
    
    public var chineseScript: ChineseScript {
        get {
            let setting = userDefaults.string(forKey: chineseScriptKeyName) ?? ""
            return ChineseScript(rawValue: setting) ?? .traditionalHK
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: chineseScriptKeyName)
        }
    }
    
    public var isEnablingEnglishInput: Bool {
        get {
            let setting = userDefaults.string(forKey: enableEnglishInputKeyName) ?? ""
            return Bool(setting) ?? true
        }
        set {
            userDefaults.set(newValue.description, forKey: enableEnglishInputKeyName)
        }
    }
    
    public var symbolShape: SymbolShape {
        get {
            let setting = userDefaults.string(forKey: symbolShapeKeyName) ?? ""
            return SymbolShape(rawValue: setting) ?? .smart
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: symbolShapeKeyName)
        }
    }
    
    public var spaceOutputMode: SpaceOutputMode {
        get {
            let setting = userDefaults.string(forKey: spaceOutputModeKeyName) ?? ""
            return SpaceOutputMode(rawValue: setting) ?? .input
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: spaceOutputModeKeyName)
        }
    }
    
    init() {
        let suiteName = "group.org.cantoboard"
        let appGroupDefaults = UserDefaults(suiteName: suiteName)
        if let appGroupDefaults = appGroupDefaults {
            NSLog("Using UserDefaults \(suiteName).")
            userDefaults = appGroupDefaults
        } else {
            NSLog("Cannot open app group UserDefaults. Falling back to UserDefaults.standard.")
            userDefaults = UserDefaults.standard
        }
    }
    
    public static var shared: Settings = Settings()
}
