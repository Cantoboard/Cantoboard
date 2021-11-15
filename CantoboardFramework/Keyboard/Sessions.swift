//
//  Settings.swift
//  CantoboardFramework
//
//  Created by Alex Man on 2/23/21.
//

import Foundation

import CocoaLumberjackSwift

public enum CharForm: String, Codable {
    case traditional = "zh-HK"
    case simplified = "zh-CN"
}

public struct SessionState: Codable, Equatable {
    private static let sessionKeyName = "SessionState"
    
    private static let defaultInputMode: InputMode = .mixed
    private static let defaultPrimarySchema: RimeSchema = .jyutping
    private static let defaultCharForm: CharForm = .traditional
    private static let defaultCurrency = "$"
    private static let defaultDomain = "hk"

    public let currencySymbol: String = getLocalCurrencyCode()
    public let localDomain: String = getLocalDomain()
    
    private static func getLocalCurrencyCode() -> String {
        if let currencySymbol = Locale.current.currencySymbol {
            if currencySymbol == "¤" { return Self.defaultCurrency }
            
            let currencySymbolWithoutLetters = currencySymbol.filter({ $0.isSymbol })
            if currencySymbolWithoutLetters.isEmpty {
                return currencySymbol
            }
            return currencySymbolWithoutLetters
        }
        return Self.defaultCurrency
    }
    
    private static func getLocalDomain() -> String {
        return (Locale.current.regionCode ?? defaultDomain).lowercased()
    }
    
    
    public var lastInputMode: InputMode {
        didSet { save() }
    }
    
    public var lastPrimarySchema: RimeSchema {
        didSet { save() }
    }
    
    public var lastCharForm: CharForm {
        didSet { save() }
    }

    private init() {
        lastInputMode = Self.defaultInputMode
        lastPrimarySchema = Self.defaultPrimarySchema
        lastCharForm = Self.defaultCharForm
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastInputMode = try container.decodeIfPresent(InputMode.self, forKey: .lastInputMode) ?? Self.defaultInputMode
        lastPrimarySchema = try container.decodeIfPresent(RimeSchema.self, forKey: .lastPrimarySchema) ?? Self.defaultPrimarySchema
        lastCharForm = try container.decodeIfPresent(CharForm.self, forKey: .lastCharForm) ?? Self.defaultCharForm
    }
    
    private func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.sessionKeyName)
        } else {
            DDLogInfo("Failed to save \(self)")
        }
    }
    
    static var main: SessionState = Self.load()
    
    private static func load() -> SessionState {
        var state = SessionState()
        if let saved = UserDefaults.standard.object(forKey: Self.sessionKeyName) as? Data {
            let decoder = JSONDecoder()
            do {
                state = try decoder.decode(SessionState.self, from: saved)
            } catch {
                DDLogInfo("Failed to load \(saved). Using default. Error: \(error)")
            }
        }
        
        return state
    }
}
