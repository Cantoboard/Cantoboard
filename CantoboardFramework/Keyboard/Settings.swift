//
//  Settings.swift
//  CantoboardFramework
//
//  Created by Alex Man on 2/23/21.
//

import Foundation

import CocoaLumberjackSwift

public enum CharForm: String, Codable {
    case traditionalHK = "zh-HK"
    case traditionalTW = "zh-TW"
    case simplified = "zh-CN"
}

public enum InputMode: String, Codable {
    case mixed = "mixed"
    case chinese = "chinese"
    case english = "english"
}

public enum SymbolShape: String, Codable {
    case half = "half"
    case full = "full"
    case smart = "smart"
}

public enum SpaceOutputMode: String, Codable {
    case bestEnglishCandidate = "bestEnglishCandidate"
    case bestCandidate = "bestCandidate"
}

public enum ToneInputMode: String, Codable {
    case longPress = "longPress"
    case vxq = "vxq"
}

public enum EnglishLocale: String, Codable {
    case us = "en_US"
    case gb = "en_GB"
    case ca = "en_CA"
    case au = "en_AU"
}

// If any of these settings is changed, we have to redeploy Rime.
public struct RimeSettings: Codable, Equatable {
    public var enableCorrector: Bool
    
    public init() {
        enableCorrector = false
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enableCorrector = try container.decodeIfPresent(Bool.self, forKey: .enableCorrector) ?? false
    }
}

// If the input method doesn't have full access, the following settings will be not be reloaded from disk.
public struct SessionSettings: Codable, Equatable {
    private static let defaultInputMode: InputMode = .mixed
    private static let defaultPrimarySchema: RimeSchema = .jyutping
    
    public var lastInputMode: InputMode
    public var lastPrimarySchema: RimeSchema

    public init() {
        lastInputMode = Self.defaultInputMode
        lastPrimarySchema = Self.defaultPrimarySchema
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastInputMode = try container.decodeIfPresent(InputMode.self, forKey: .lastInputMode) ?? Self.defaultInputMode
        lastPrimarySchema = try container.decodeIfPresent(RimeSchema.self, forKey: .lastPrimarySchema) ?? Self.defaultPrimarySchema
    }
}

public struct Settings: Codable, Equatable {
    private static let settingsKeyName = "Settings"
    private static let defaultCharForm: CharForm = .traditionalTW
    private static let defaultMixedModeEnabled: Bool = true
    private static let defaultAutoCapEnabled: Bool = true
    private static let defaultSmartFullStopEnabled: Bool = true
    private static let defaultSymbolShape: SymbolShape = .smart
    private static let defaultSpaceOutputMode: SpaceOutputMode = .bestCandidate
    private static let defaultToneInputMode: ToneInputMode = .longPress
    private static let defaultRimeSettings: RimeSettings = RimeSettings()
    private static let defaultEnglishLocale: EnglishLocale = .us
    private static let defaultShowRomanization: Bool = false
    private static let defaultAudioFeedbackEnabled: Bool = true
    private static let defaultTapHapticFeedbackEnabled: Bool = false
    private static let defaultSessionSettings: SessionSettings = SessionSettings()

    public var charForm: CharForm
    public var isMixedModeEnabled: Bool
    public var isAutoCapEnabled: Bool
    public var isSmartFullStopEnabled: Bool
    public var symbolShape: SymbolShape
    public var spaceOutputMode: SpaceOutputMode
    public var toneInputMode: ToneInputMode
    public var rimeSettings: RimeSettings
    public var englishLocale: EnglishLocale
    public var shouldShowRomanization: Bool
    public var isAudioFeedbackEnabled: Bool
    public var isTapHapticFeedbackEnabled: Bool
    public var lastSessionSettings: SessionSettings
    
    public init() {
        charForm = Self.defaultCharForm
        isMixedModeEnabled = Self.defaultMixedModeEnabled
        isAutoCapEnabled = Self.defaultAutoCapEnabled
        isSmartFullStopEnabled = Self.defaultSmartFullStopEnabled
        symbolShape = Self.defaultSymbolShape
        spaceOutputMode = Self.defaultSpaceOutputMode
        toneInputMode = Self.defaultToneInputMode
        rimeSettings = Self.defaultRimeSettings
        englishLocale = Self.defaultEnglishLocale
        shouldShowRomanization = Self.defaultShowRomanization
        isAudioFeedbackEnabled = Self.defaultAudioFeedbackEnabled
        isTapHapticFeedbackEnabled = Self.defaultTapHapticFeedbackEnabled
        lastSessionSettings = Self.defaultSessionSettings
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.charForm = try container.decodeIfPresent(CharForm.self, forKey: .charForm) ?? Settings.defaultCharForm
        self.isMixedModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .isMixedModeEnabled) ?? Settings.defaultMixedModeEnabled
        self.isAutoCapEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAutoCapEnabled) ?? Settings.defaultAutoCapEnabled
        self.isSmartFullStopEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSmartFullStopEnabled) ?? Settings.defaultSmartFullStopEnabled
        self.symbolShape = try container.decodeIfPresent(SymbolShape.self, forKey: .symbolShape) ?? Settings.defaultSymbolShape
        self.spaceOutputMode = Settings.defaultSpaceOutputMode
        self.toneInputMode = try container.decodeIfPresent(ToneInputMode.self, forKey: .toneInputMode) ?? Settings.defaultToneInputMode
        self.rimeSettings = try container.decodeIfPresent(RimeSettings.self, forKey: .rimeSettings) ?? Settings.defaultRimeSettings
        self.englishLocale = try container.decodeIfPresent(EnglishLocale.self, forKey: .englishLocale) ?? Settings.defaultEnglishLocale
        self.shouldShowRomanization = try container.decodeIfPresent(Bool.self, forKey: .shouldShowRomanization) ?? Settings.defaultShowRomanization
        self.isAudioFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAudioFeedbackEnabled) ?? Settings.defaultAudioFeedbackEnabled
        self.isTapHapticFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .isTapHapticFeedbackEnabled) ?? Settings.defaultTapHapticFeedbackEnabled
        self.lastSessionSettings = try container.decodeIfPresent(SessionSettings.self, forKey: .lastSessionSettings) ?? Settings.defaultSessionSettings
    }
    
    private static var _cached: Settings?
    
    public static var cached: Settings {
        get {
            if _cached == nil {
                return reload()
            }
            return _cached!
        }
    }
    
    public static func reload() -> Settings {
        if let saved = userDefaults.object(forKey: settingsKeyName) as? Data {
            let prevSetting = _cached
            let decoder = JSONDecoder()
            do {
                let setting = try decoder.decode(Settings.self, from: saved)
                _cached = setting
                if let prevSetting = prevSetting, !hasFullAccess {
                    // If the app doesn't have full acesss, preserve lastSessionSettings in memory.
                    _cached!.lastSessionSettings = prevSetting.lastSessionSettings
                }
                return setting
            } catch {
                DDLogInfo("Failed to load \(saved). Falling back to default settings. Error: \(error)")
            }
        }
        
        _cached = Settings()
        return _cached!
    }
    
    public static func save(_ settings: Settings) {
        _cached = settings
        guard hasFullAccess else {
            DDLogInfo("Skip updating UserDefaults as we don't have full access.")
            return
        }
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(settings) {
            userDefaults.set(encoded, forKey: settingsKeyName)
        } else {
            DDLogInfo("Failed to save \(settings)")
        }
    }
    
    public static var hasFullAccess = true
    
    private static var userDefaults: UserDefaults = initUserDefaults()
    
    private static func initUserDefaults() -> UserDefaults {
        let suiteName = "group.org.cantoboard"
        let appGroupDefaults = UserDefaults(suiteName: suiteName)
        if let appGroupDefaults = appGroupDefaults {
            DDLogInfo("Using UserDefaults \(suiteName).")
            return appGroupDefaults
        } else {
            DDLogInfo("Cannot open app group UserDefaults. Falling back to UserDefaults.standard.")
            return UserDefaults.standard
        }
    }
}
