//
//  KeyboardViewLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/24/21.
//

import Foundation
import UIKit

enum GroupLayoutDirection {
    case left, middle, right
}

protocol KeyboardViewLayout {
    static var numOfRows: Int { get };
    
    static var letters: [[[KeyCap]]] { get };
    static var numbersHalf: [[[KeyCap]]] { get };
    static var symbolsHalf: [[[KeyCap]]] { get };
    static var numbersFull: [[[KeyCap]]] { get };
    static var symbolsFull: [[[KeyCap]]] { get };
    
    static func layoutKeyViews(keyRowView: KeyRowView, leftKeys: [KeyView], middleKeys: [KeyView], rightKeys: [KeyView], layoutConstants: LayoutConstants) -> [CGRect]
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap?
    static func getKeyHeight(atRow: Int, layoutConstants: LayoutConstants) -> CGFloat
    static func getSwipeDownKeyCap(keyCap: KeyCap, keyboardState: KeyboardState) -> KeyCap?
    static func isSwipeDownKeyShiftMorphing(keyCap: KeyCap) -> Bool
}

class CommonContextualKeys {
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap? {
        let shouldShowToggleChar = keyboardState.keyboardIdiom == .phone && !Settings.cached.showBottomLeftSwitchLangButton
        switch key {
        case .symbol:
            let toogleCharFormKeyCap = shouldShowToggleChar ? KeyCap.getToggleCharForm() : nil
            let toogleCharFormKeyCapList = toogleCharFormKeyCap != nil ? [toogleCharFormKeyCap!] : []
            let leftHint = shouldShowToggleChar ? SessionState.main.lastCharForm.caption : nil
            let keyHint = KeyCapHints(leftHint: leftHint, rightHint: "符")
            switch keyboardState.keyboardContextualType {
            case .chinese: return .character("，", keyHint, toogleCharFormKeyCapList + ["，", "。", "？", "！", "、", ".", ",", KeyCap(rime: .sym)])
            case .english: return .character(",", keyHint, toogleCharFormKeyCapList + [",", ".", "?", "!", "。", "，", KeyCap(rime: .sym)])
            case .rime: return .rime(.delimiter, keyHint, toogleCharFormKeyCapList + [KeyCap(rime: .delimiter), ".", ",", "?", "!"])
            case .url:
                var children: [KeyCap] = toogleCharFormKeyCapList + ["/", ".", ".com", ".net", ".org", ".edu"]
                if (keyboardState.isComposing) {
                    children.append(KeyCap(rime: .delimiter))
                }
                return .character(".", KeyCapHints(leftHint: leftHint, rightHint: "/"), children)
            }
        case ",": return keyboardState.keyboardContextualType.halfWidthSymbol ? "," : "，"
        case ".": return keyboardState.keyboardContextualType.halfWidthSymbol ? "." : "。"
        case .url: // For iPads
            let domains = [".net", ".org", ".edu", ".com", String("." + SessionState.main.localDomain), ".hk", ".tw", ".mo", ".cn", ".uk", ".jp"].unique()
            return .character(".com", nil, domains.map{ .character($0, nil, nil) })
        default: return nil
        }
    }
}

class CommonSwipeDownKeys {
    static func getSwipeDownKeyCapForPadShortOrFull4Rows(keyCap: KeyCap, keyboardState: KeyboardState) -> KeyCap? {
        let isInChineseContextualMode = !keyboardState.keyboardContextualType.halfWidthSymbol
        let keyCapCharacter: String?
        switch keyCap {
        case .character(let c, _, _), .cangjie(let c, _, _): keyCapCharacter = c.lowercased()
        case .currency: keyCapCharacter = "$"
        case .singleQuote: keyCapCharacter = "'"
        case .doubleQuote: keyCapCharacter = "\""
        default: keyCapCharacter = nil
        }
        switch keyCapCharacter {
        case "q": return "1"
        case "w": return "2"
        case "e": return "3"
        case "r": return "4"
        case "t": return "5"
        case "y": return "6"
        case "u": return "7"
        case "i": return "8"
        case "o": return "9"
        case "p": return "0"
        case "a": return "@"
        case "s": return "#"
        case "d": return KeyCap(SessionState.main.currencySymbol)
        case "f": return KeyCap(isInChineseContextualMode ? "／" : "/").symbolTransform(state: keyboardState)
        case "g": return KeyCap(isInChineseContextualMode ? "（" : "(").symbolTransform(state: keyboardState)
        case "h": return KeyCap(isInChineseContextualMode ? "）" : ")").symbolTransform(state: keyboardState)
        case "j": return "「"
        case "k": return "」"
        case "l": return .singleQuote
        case "z": return "%"
        case "x": return isInChineseContextualMode ? "—" : "-"
        case "c": return isInChineseContextualMode ? "～" : "~"
        case "v": return isInChineseContextualMode ? "⋯" : "…"
        case "b": return isInChineseContextualMode ? "、" : "､"
        case "n": return isInChineseContextualMode ? "；" : ";"
        case "m": return KeyCap(isInChineseContextualMode ? "：" : ":").symbolTransform(state: keyboardState)
        case ",": return "!"
        case ".": return "?"
        case "，": return "！"
        case "。": return "？"
        case "@": return "^"
        case "#": return "_"
        case "$": return isInChineseContextualMode ? "｜" : "|"
        case "/": return "\\"
        case "／": return "＼"
        case "(": return "["
        case ")": return "]"
        case "（": return "［"
        case "）": return "］"
        case "｢": return "{"
        case "｣": return "}"
        case "「": return "｛"
        case "」": return "｝"
        case "'": return .doubleQuote
        case "%": return "*"
        case "-", "—": return "&"
        case "~", "～": return "+"
        case "…", "⋯": return "="
        case "､": return "•"
        case "、": return "·"
        case ";": return "<"
        case "；": return "《"
        case ":": return ">"
        case "：": return "》"
        default: return nil
        }
    }
}

extension LayoutIdiom {
    var keyboardViewLayout: KeyboardViewLayout.Type {
        switch self {
        case .phone: return PhoneKeyboardViewLayout.self
        case .pad(.padShort): return PadShortKeyboardViewLayout.self
        case .pad(.padFull4Rows): return PadFull4RowsKeyboardViewLayout.self
        case .pad(.padFull5Rows): return PadFull5RowsKeyboardViewLayout.self
        }
    }
}
