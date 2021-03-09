//
//  KeyCap.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation
import UIKit

/**
 This action enum specifies all currently supported keyboard
 actions and their standard behavior.
 
 Most actions have a standard behavior for a certain gesture
 when their used in system keyboards. This standard behavior
 is provided through `standardInputViewControllerAction` and
 `standardTextDocumentProxyAction`. Keyboard action handlers
 can choose to use these standard actions or ignore them.
 
 Many actions require manual handling since they do not have
 universal, app-agnostic behaviors. For instance, the `image`
 action depends on what you want to do with the tapped image.
 Actions like these are a way for you to express your intent,
 but require manual handling in a custom action handler.
*/
enum KeyCap: Equatable, ExpressibleByStringLiteral {
    case
    none,
    backspace,
    capsLock,
    character(String),
    characterWithTone(String),
    emoji(String),
    keyboardType(KeyboardType),
    newLine,
    nextKeyboard,
    space,
    shift(_ state: KeyboardShiftState),
    rime(RimeChar),
    contexualSymbols(ContextualType),
    chineseScript(ChineseScript)
    
    public init(stringLiteral value: String) {
        self = .character(value)
    }
    
    func getAction(/* type, state*/) -> KeyboardAction {
        switch self {
        case .none: return .none
        case .backspace: return .backspace
        case .capsLock: return .capsLock
        case .character(let c): return .character(c)
        case .characterWithTone(let c): return .character(c)
        case .emoji(let e): return .emoji(e)
        case .keyboardType(let type): return .keyboardType(type)
        case .newLine: return .newLine
        case .nextKeyboard: return .nextKeyboard
        case .space: return .space
        case .shift(let shiftState): return .shift(shiftState)
        case .rime(let rc): return .rime(rc)
        case .contexualSymbols(.chinese): return "，"
        case .contexualSymbols(.english): return ","
        case .contexualSymbols(.rime): return .rime(.delimiter)
        case .contexualSymbols(.url): return "."
        case .chineseScript(let cs): return .setChineseScript(cs)
        }
    }
    
    var buttonFont: UIFont {
        switch self {
        case .rime: return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(14)
        // case .contexualSymbols(.rime): return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(18)
        default: return .preferredFont(forTextStyle: buttonFontStyle)
        }
    }
    
    var popupFont: UIFont {
        switch self {
        case .chineseScript, .rime(.delimiter): return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(30)
        case .rime: return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(14)
        case .character(".com"), .character(".net"), .character(".org"), .character(".edu"): return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(14)
        default: return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(30)
        }
    }
    
    var buttonFontStyle: UIFont.TextStyle {
        switch self {
        case .character, .characterWithTone, .emoji, .contexualSymbols: return .title2
        case .keyboardType(.emojis): return .title1
        default: return .body
        }
    }
    
    var buttonBgColor: UIColor {
        switch self {
        case .character, .characterWithTone, .space, .contexualSymbols: return ButtonColor.InputKeyBackgroundColor
        case .shift(.uppercased), .shift(.capsLocked): return ButtonColor.ShiftKeyHighlightedBackgroundColor
        default: return ButtonColor.SystemKeyBackgroundColor
        }
    }
    
    var buttonFgColor: UIColor {
        if self == .shift(.uppercased) || self == .shift(.capsLocked) {
            return ButtonColor.ShiftKeyHighlightedForegroundColor
        }
        return ButtonColor.KeyForegroundColor
    }
    
    // TODO Return images < iOS 12
    var buttonImage: UIImage? {
        switch self {
        case .backspace: return ButtonImage.Backspace
        case .nextKeyboard: return ButtonImage.Globe
        case .shift(.lowercased): return ButtonImage.Shift
        case .shift(.uppercased): return ButtonImage.ShiftFilled
        case .shift(.capsLocked): return ButtonImage.CapLockFilled
        case .keyboardType(.emojis): return ButtonImage.EmojiKeyboard
        // case .keyboardType(.numeric): return ButtonImage.oneTwoThree
        default: return nil
        }
    }
    
    var buttonText: String? {
        switch self {
        case .character(let text): return text
        case .characterWithTone(let text): return text
        case .newLine: return "return"
        case .space: return "space"
        case .keyboardType(.numeric): return "123"
        case .keyboardType(.symbolic): return "#+="
        case .keyboardType(.alphabetic): return "ABC"
        case .rime(.tone1): return "陰平"
        case .rime(.tone2): return "陰上"
        case .rime(.tone3): return "陰去"
        case .rime(.tone4): return "陽平"
        case .rime(.tone5): return "陽上"
        case .rime(.tone6): return "陽去"
        case .rime(.delimiter): return "斷"
        case .contexualSymbols(.chinese): return "，"
        case .contexualSymbols(.english): return ","
        case .contexualSymbols(.rime): return "斷"
        case .contexualSymbols(.url): return "."
        case .chineseScript(.traditionalHK): return "繁"
        case .chineseScript(.simplified): return "簡"
        default: return nil
        }
    }
    
    var buttonHint: String? {
        switch self {
        case .characterWithTone("A"), .characterWithTone("a"): return "4"
        case .characterWithTone("S"), .characterWithTone("s"): return "5"
        case .characterWithTone("D"), .characterWithTone("d"): return "6"
        case .characterWithTone("Z"), .characterWithTone("z"): return "1"
        case .characterWithTone("X"), .characterWithTone("x"): return "2"
        case .characterWithTone("C"), .characterWithTone("c"): return "3"
        // case .contexualSymbols(.english), .character(","), .character("."), .character("?"), .character("!"): return "半"
        case .contexualSymbols(.chinese), .character("，"), .character("。"), .character("？"), .character("！"): return "全"
        case .rime(.tone1): return "1"
        case .rime(.tone2): return "2"
        case .rime(.tone3): return "3"
        case .rime(.tone4): return "4"
        case .rime(.tone5): return "5"
        case .rime(.tone6): return "6"
        case .chineseScript(let cs): return Settings.shared.chineseScript == cs ? "*" : nil
        default: return nil
        }
    }
    
    func buttonWidth(_ layoutConstants: LayoutConstants) -> CGFloat {
        switch self {
        case .shift, .capsLock, .keyboardType(.symbolic), .backspace:
            return layoutConstants.shiftButtonWidth
        case .newLine:
            return 1.5 * layoutConstants.systemButtonWidth
        case .character, .characterWithTone, .contexualSymbols:
            return layoutConstants.keyButtonWidth
        default:
            return layoutConstants.systemButtonWidth
        }
    }
    
    var hasPopup: Bool {
        switch self {
        case .character, .characterWithTone, .contexualSymbols: return true
        case .keyboardType(.emojis): return true
        default: return false
        }
    }
    
    var childrenKeyCaps: [KeyCap] {
        switch self {
        case .characterWithTone(let c):
            switch c {
            case "A", "a": return [.character(c), .rime(RimeChar.tone4)]
            case "S", "s": return [.character(c), .rime(RimeChar.tone5)]
            case "D", "d": return [.character(c), .rime(RimeChar.tone6)]
            case "Z", "z": return [.character(c), .rime(RimeChar.tone1)]
            case "X", "x": return [.character(c), .rime(RimeChar.tone2)]
            case "C", "c": return [.character(c), .rime(RimeChar.tone3)]
            default: return [self]
            }
        // case .character(",") : return [self, "'", "?", "."]
        case .contexualSymbols(.chinese): return ["。", "，", "？", "！", ".", ","]
        case .contexualSymbols(.english): return [".", ",", "?", "!", "。", "，"]
        case .contexualSymbols(.rime): return [self, ".", ",", "?", "!"]
        case .contexualSymbols(.url): return [".", ".com", ".net", ".org", ".edu", .rime(.delimiter)]
        case .keyboardType(.emojis):
            if Settings.shared.chineseScript != .simplified {
                return [.chineseScript(.traditionalHK), .chineseScript(.simplified)]
            } else {
                return [.chineseScript(.simplified), .chineseScript(.traditionalHK) ]
            }
        case .character("-"): return ["-", "–", "—", "•"]
        case .character("/"): return ["/", "\\"]
        case .character("$"): return ["¢", "$", "€", "£", "¥", "₩", "₽"]
        case .character("&"): return ["&", "§"]
        case .character("\""): return ["\"", "”", "“", "„", "»", "«"]
        case .character("."): return [".", "…"]
        case .character("?"): return ["?", "¿"]
        case .character("!"): return ["!", "¡"]
        case .character("‘"): return ["'", "’", "‘", "`"]
        case .character("="): return ["=", "≠", "≈"]
        default: return [self]
        }
    }
}

let FrameworkBundle = Bundle(for: KeyView.self)

class ButtonImage {
    static let Globe = UIImage(systemName: "globe")
    static let Backspace = UIImage(systemName: "delete.left")
    static let Shift = UIImage(systemName: "shift")
    static let ShiftFilled = UIImage(systemName: "shift.fill")
    static let CapLockFilled = UIImage(systemName: "capslock.fill")
    static let EmojiKeyboard = UIImage(systemName: "face.smiling", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
    // static let oneTwoThree = UIImage(systemName: "textformat.123")
}


class ButtonColor {
    static let SystemKeyBackgroundColor = UIColor(named: "systemKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let InputKeyBackgroundColor = UIColor(named: "inputKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let KeyForegroundColor = UIColor(named: "keyForegroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let PopupBackgroundColor = UIColor(named: "PopupBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let KeyShadowColor = UIColor(named: "keyShadowColor", in: FrameworkBundle, compatibleWith: nil)!
    static let ShiftKeyHighlightedBackgroundColor = UIColor(named: "ShiftKeyHighlightedBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let ShiftKeyHighlightedForegroundColor = UIColor(named: "ShiftKeyHighlightedForegroundColor", in: FrameworkBundle, compatibleWith: nil)!
}
