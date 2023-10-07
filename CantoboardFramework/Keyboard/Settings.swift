//
//  Settings.swift
//  CantoboardFramework
//
//  Created by Alex Man on 2/23/21.
//

import Foundation

import CocoaLumberjackSwift

public enum CompositionMode: String, Codable {
    case multiStage = "multiStage"
    case immediate = "immediate"
}

public enum InputMode: String, Codable {
    case mixed = "mixed"
    case chinese = "chinese"
    case english = "english"
    
    var afterToggle: InputMode {
        switch self {
        case .mixed: return .english
        case .chinese: return .english
        case .english: return Settings.cached.isMixedModeEnabled ? .mixed : .chinese
        }
    }
}

public enum SymbolShape: String, Codable {
    case full = "full"
    case half = "half"
    case smart = "smart"
}

public enum SpaceAction: String, Codable {
    case insertCandidate = "insertCandidate"
    case insertText = "insertText"
    case nextPage = "nextPage"
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

public enum CandidateFontSize: String, Codable {
    case normal = "normal"
    case large = "large"
    
    var scale: CGFloat {
        switch self {
        case .normal: return 1
        case .large: return 1.2
        }
    }
}

public enum CandidateSelectMode: String, Codable {
    case expandDownward = "expandDownward"
    case scrollRight = "scrollRight"
}

public enum CangjieVersion: String, Codable {
    case cangjie3 = "cangjie3"
    case cangjie5 = "cangjie5"
    
    var toRimeCJSchema: RimeSchema {
        switch self {
        case .cangjie3: return .cangjie3
        case .cangjie5: return .cangjie5
        }
    }
    
    var toRimeQuickSchema: RimeSchema {
        switch self {
        case .cangjie3: return .quick3
        case .cangjie5: return .quick5
        }
    }
}

public enum CangjieKeyCapMode: String, Codable {
    case letter = "letter"
    case cangjieRoot = "cangjieRoot"
}

public enum ShowRomanizationMode: String, Codable {
    case always = "always"
    case onlyInNonCantoneseMode = "onlyInNonCantoneseMode"
    case never = "never"
}

public enum FullWidthSpaceMode: String, Codable {
    case off = "off"
    case shift = "shift"
}

public enum Quick3CandidateMode: String, Codable {
    case sortByFreq = "sortByFreq"
    case fixedOrder = "fixedOrder"
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

public struct Settings: Codable, Equatable {
    private static let settingsKeyName = "Settings"
    private static let defaultMixedModeEnabled: Bool = true
    private static let defaultAutoCapEnabled: Bool = true
    private static let defaultSmartEnglishSpaceEnabled: Bool = true
    private static let defaultSmartFullStopEnabled: Bool = true
    private static let defaultCandidateFontSize: CandidateFontSize = .normal
    private static let defaultCandidateSelectMode: CandidateSelectMode = .expandDownward
    private static let defaultSymbolShape: SymbolShape = .smart
    private static let defaultSmartSymbolShapeDefault: SymbolShape = .full
    private static let defaultSpaceAction: SpaceAction = .insertText
    private static let defaultToneInputMode: ToneInputMode = .longPress
    private static let defaultRimeSettings: RimeSettings = RimeSettings()
    private static let defaultEnglishLocale: EnglishLocale = .us
    private static let defaultShowRomanizationMode: ShowRomanizationMode = .onlyInNonCantoneseMode
    private static let defaultAudioFeedbackEnabled: Bool = true
    private static let defaultTapHapticFeedbackEnabled: Bool = false
    private static let defaultShowEnglishExactMatch: Bool = true
    private static let defaultCompositionMode: CompositionMode = .multiStage
    private static let defaultEnableCharPreview: Bool = true
    private static let defaultPressSymbolKeysEnabled: Bool = true
    private static let defaultEnableHKCorrection: Bool = true
    private static let defaultFullWidthSpaceMode: FullWidthSpaceMode = .off
    private static let defaultEnablePredictiveText: Bool = true
    private static let defaultPredictiveTextOffensiveWord: Bool = false
    private static let defaultFullPadCandidateBar: Bool = true
    private static let defaultPadLeftSysKeyAsKeyboardType: Bool = false
    private static let defaultShowBottomLeftSwitchLangButton: Bool = false
    private static let defaultCangjieVersion: CangjieVersion = .cangjie3
    private static let defaultCangjieKeyCapMode: CangjieKeyCapMode = .cangjieRoot
    private static let defaultQuick3CandidateMode: Quick3CandidateMode = .fixedOrder
    private static let defaultQuick3FixedOrderNumPopularCandidates: UInt8 = 3

    public var isMixedModeEnabled: Bool
    public var isAutoCapEnabled: Bool
    public var isSmartEnglishSpaceEnabled: Bool = true
    public var isSmartFullStopEnabled: Bool
    public var candidateFontSize: CandidateFontSize
    public var candidateSelectMode: CandidateSelectMode
    public var symbolShape: SymbolShape
    public var smartSymbolShapeDefault: SymbolShape
    public var spaceAction: SpaceAction
    public var toneInputMode: ToneInputMode
    public var rimeSettings: RimeSettings
    public var englishLocale: EnglishLocale
    public var showRomanizationMode: ShowRomanizationMode
    public var isAudioFeedbackEnabled: Bool
    public var isTapHapticFeedbackEnabled: Bool
    public var shouldShowEnglishExactMatch: Bool
    public var compositionMode: CompositionMode
    public var enableCharPreview: Bool
    public var isLongPressSymbolKeysEnabled: Bool
    public var enableHKCorrection: Bool
    public var fullWidthSpaceMode: FullWidthSpaceMode
    public var enablePredictiveText: Bool
    public var predictiveTextOffensiveWord: Bool
    public var fullPadCandidateBar: Bool
    public var padLeftSysKeyAsKeyboardType: Bool
    public var showBottomLeftSwitchLangButton: Bool
    public var cangjieVersion: CangjieVersion
    public var cangjieKeyCapMode: CangjieKeyCapMode
    public var quick3CandidateMode: Quick3CandidateMode
    public var quick3FixedOrderNumPopularCandidates: UInt8

    public init() {
        isMixedModeEnabled = Self.defaultMixedModeEnabled
        isAutoCapEnabled = Self.defaultAutoCapEnabled
        isSmartEnglishSpaceEnabled = Self.defaultSmartEnglishSpaceEnabled
        isSmartFullStopEnabled = Self.defaultSmartFullStopEnabled
        candidateFontSize = Self.defaultCandidateFontSize
        candidateSelectMode = Self.defaultCandidateSelectMode
        symbolShape = Self.defaultSymbolShape
        smartSymbolShapeDefault = Self.defaultSmartSymbolShapeDefault
        spaceAction = Self.defaultSpaceAction
        toneInputMode = Self.defaultToneInputMode
        rimeSettings = Self.defaultRimeSettings
        englishLocale = Self.defaultEnglishLocale
        showRomanizationMode = Self.defaultShowRomanizationMode
        isAudioFeedbackEnabled = Self.defaultAudioFeedbackEnabled
        isTapHapticFeedbackEnabled = Self.defaultTapHapticFeedbackEnabled
        shouldShowEnglishExactMatch = Self.defaultShowEnglishExactMatch
        compositionMode = Self.defaultCompositionMode
        enableCharPreview = Self.defaultEnableCharPreview
        isLongPressSymbolKeysEnabled = Self.defaultPressSymbolKeysEnabled
        enableHKCorrection = Self.defaultEnableHKCorrection
        fullWidthSpaceMode = Self.defaultFullWidthSpaceMode
        enablePredictiveText = Self.defaultEnablePredictiveText
        predictiveTextOffensiveWord = Self.defaultPredictiveTextOffensiveWord
        fullPadCandidateBar = Self.defaultFullPadCandidateBar
        padLeftSysKeyAsKeyboardType = Self.defaultPadLeftSysKeyAsKeyboardType
        showBottomLeftSwitchLangButton = Self.defaultShowBottomLeftSwitchLangButton
        cangjieVersion = Self.defaultCangjieVersion
        cangjieKeyCapMode = Self.defaultCangjieKeyCapMode
        quick3CandidateMode = Self.defaultQuick3CandidateMode
        quick3FixedOrderNumPopularCandidates = Self.defaultQuick3FixedOrderNumPopularCandidates
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isMixedModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .isMixedModeEnabled) ?? Settings.defaultMixedModeEnabled
        self.isAutoCapEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAutoCapEnabled) ?? Settings.defaultAutoCapEnabled
        self.isSmartFullStopEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSmartFullStopEnabled) ?? Settings.defaultSmartFullStopEnabled
        self.isSmartEnglishSpaceEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSmartEnglishSpaceEnabled) ?? Settings.defaultSmartEnglishSpaceEnabled
        self.candidateFontSize = try container.decodeIfPresent(CandidateFontSize.self, forKey: .candidateFontSize) ?? Settings.defaultCandidateFontSize
        self.candidateSelectMode = try container.decodeIfPresent(CandidateSelectMode.self, forKey: .candidateSelectMode) ?? Settings.defaultCandidateSelectMode
        self.symbolShape = try container.decodeIfPresent(SymbolShape.self, forKey: .symbolShape) ?? Settings.defaultSymbolShape
        self.smartSymbolShapeDefault = try container.decodeIfPresent(SymbolShape.self, forKey: .smartSymbolShapeDefault) ?? Settings.defaultSmartSymbolShapeDefault
        self.spaceAction = try container.decodeIfPresent(SpaceAction.self, forKey: .spaceAction) ?? Settings.defaultSpaceAction
        self.toneInputMode = try container.decodeIfPresent(ToneInputMode.self, forKey: .toneInputMode) ?? Settings.defaultToneInputMode
        self.rimeSettings = try container.decodeIfPresent(RimeSettings.self, forKey: .rimeSettings) ?? Settings.defaultRimeSettings
        self.englishLocale = try container.decodeIfPresent(EnglishLocale.self, forKey: .englishLocale) ?? Settings.defaultEnglishLocale
        self.showRomanizationMode = try container.decodeIfPresent(ShowRomanizationMode.self, forKey: .showRomanizationMode) ?? Settings.defaultShowRomanizationMode
        self.isAudioFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAudioFeedbackEnabled) ?? Settings.defaultAudioFeedbackEnabled
        self.isTapHapticFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .isTapHapticFeedbackEnabled) ?? Settings.defaultTapHapticFeedbackEnabled
        self.shouldShowEnglishExactMatch = try container.decodeIfPresent(Bool.self, forKey: .shouldShowEnglishExactMatch) ?? Settings.defaultShowEnglishExactMatch
        self.compositionMode = try container.decodeIfPresent(CompositionMode.self, forKey: .compositionMode) ?? Settings.defaultCompositionMode
        self.enableCharPreview = try container.decodeIfPresent(Bool.self, forKey: .enableCharPreview) ?? Settings.defaultEnableCharPreview
        self.isLongPressSymbolKeysEnabled = try container.decodeIfPresent(Bool.self, forKey: .isLongPressSymbolKeysEnabled) ?? Settings.defaultPressSymbolKeysEnabled
        self.enableHKCorrection = try container.decodeIfPresent(Bool.self, forKey: .enableHKCorrection) ?? Settings.defaultEnableHKCorrection
        self.fullWidthSpaceMode = try container.decodeIfPresent(FullWidthSpaceMode.self, forKey: .fullWidthSpaceMode) ?? Settings.defaultFullWidthSpaceMode
        self.enablePredictiveText = try container.decodeIfPresent(Bool.self, forKey: .enablePredictiveText) ?? Settings.defaultEnablePredictiveText
        self.predictiveTextOffensiveWord = try container.decodeIfPresent(Bool.self, forKey: .predictiveTextOffensiveWord) ?? Settings.defaultPredictiveTextOffensiveWord
        self.fullPadCandidateBar = try container.decodeIfPresent(Bool.self, forKey: .fullPadCandidateBar) ?? Settings.defaultFullPadCandidateBar
        self.padLeftSysKeyAsKeyboardType = try container.decodeIfPresent(Bool.self, forKey: .padLeftSysKeyAsKeyboardType) ?? Settings.defaultPadLeftSysKeyAsKeyboardType
        self.showBottomLeftSwitchLangButton = try container.decodeIfPresent(Bool.self, forKey: .showBottomLeftSwitchLangButton) ?? Settings.defaultShowBottomLeftSwitchLangButton
        self.cangjieVersion = try container.decodeIfPresent(CangjieVersion.self, forKey: .cangjieVersion) ?? Settings.defaultCangjieVersion
        self.cangjieKeyCapMode = try container.decodeIfPresent(CangjieKeyCapMode.self, forKey: .cangjieKeyCapMode) ?? Settings.defaultCangjieKeyCapMode
        self.quick3CandidateMode = try container.decodeIfPresent(Quick3CandidateMode.self, forKey: .quick3CandidateMode) ?? Settings.defaultQuick3CandidateMode
        self.quick3FixedOrderNumPopularCandidates = try container.decodeIfPresent(UInt8.self, forKey: .quick3FixedOrderNumPopularCandidates) ?? Settings.defaultQuick3FixedOrderNumPopularCandidates
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
            let decoder = JSONDecoder()
            do {
                let setting = try decoder.decode(Settings.self, from: saved)
                _cached = setting
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
