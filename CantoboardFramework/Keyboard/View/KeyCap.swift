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
enum SpaceKeyMode: String {
    case space = "space"
    case select = "select"
    case nextPage = "next page"
}

enum ReturnKeyType: Int {
    case confirm = -1
    case `default` = 0
    case go = 1
    case google = 2
    case join = 3
    case next = 4
    case route = 5
    case search = 6
    case send = 7
    case yahoo = 8
    case done = 9
    case emergencyCall = 10

    @available(iOS 9.0, *)
    case `continue` = 11
    
    public init(_ returnKeyType: UIReturnKeyType) {
        self = ReturnKeyType(rawValue: returnKeyType.rawValue) ?? .default
    }
}

enum KeyCapType {
    case input, system, returnKey, space
}

enum ContextualKey: Equatable, ExpressibleByStringLiteral {
    case symbol
    case character(String)
    
    public init(stringLiteral value: String) {
        self = .character(value)
    }
}

indirect enum KeyCap: Equatable, ExpressibleByStringLiteral {
    case
    none,
    backspace,
    toggleInputMode(/* toMode */ InputMode, RimeSchema?),
    character(String, String?, [KeyCap]?),
    cangjie(String, Bool),
    stroke(String),
    emoji(String),
    keyboardType(KeyboardType),
    returnKey(ReturnKeyType),
    nextKeyboard,
    space(SpaceKeyMode),
    shift(_ state: KeyboardShiftState),
    rime(RimeChar, String?, [KeyCap]?),
    contextual(ContextualKey),
    reverseLookup(RimeSchema),
    changeSchema(RimeSchema),
    exportFile(String, String),
    currency,
    dismissKeyboard,
    exit,
    placeholder(KeyCap)
    
    private static let cangjieKeyCaps = ["日", "月", "金", "木", "水", "火", "土", "竹", "戈", "十", "大", "中", "一", "弓", "人", "心", "手", "口", "尸", "廿", "山", "女", "田", "難", "卜", "符"]
    
    public init(stringLiteral value: String) {
        self = .character(value, nil, nil)
    }
    
    public init(_ char: String) {
        self = .character(char, nil, nil)
    }
    
    public init(rime char: RimeChar) {
        self = .rime(char, nil, nil)
    }
    
    var action: KeyboardAction {
        switch self {
        case .none: return .none
        case .backspace: return .backspace
        case .toggleInputMode: return .toggleInputMode
        case .character(let c, _, _): return .character(c)
        case .cangjie(let c, _): return .character(c)
        case .stroke(let c): return .character(c)
        case .emoji(let e): return .emoji(e)
        case .keyboardType(let type): return .keyboardType(type)
        case .returnKey: return .newLine
        case .nextKeyboard: return .nextKeyboard
        case .space(let spaceKeyMode): return .space(spaceKeyMode)
        case .shift(let shiftState): return .shift(shiftState)
        case .rime(let rc, _, _): return .rime(rc)
        case .reverseLookup(let s): return .reverseLookup(s)
        case .changeSchema(let s): return .changeSchema(s)
        case .exportFile(let namePrefix, let path): return .exportFile(namePrefix, path)
        case .exit: return .exit
        case .currency: return .character(SessionState.main.currencySymbol)
        case .dismissKeyboard: return .dismissKeyboard
        default: return .none
        }
    }
    
    var buttonFont: UIFont {
        switch self {
        case .keyboardType(.symbolic), .returnKey(.emergencyCall): return .systemFont(ofSize: 12)
        case .rime, "^_^", .keyboardType, .returnKey, .space, "\t", .toggleInputMode: return .systemFont(ofSize: 16)
        case .cangjie(_, true): return .systemFont(ofSize: 20)
        default: return .systemFont(ofSize: 24)
        }
    }
    
    var popupFont: UIFont {
        switch self {
        case .reverseLookup, .rime(.delimiter, _, _), .rime(.sym, _, _): return .systemFont(ofSize: 24)
        case .exportFile, .exit: return .systemFont(ofSize: 12)
        case .rime, "……", "⋯⋯", "——", "^_^", ".com", ".net", ".org", ".edu": return .systemFont(ofSize: 16)
        default: return .systemFont(ofSize: 30)
        }
    }
    
    var buttonBgColor: UIColor {
        switch self {
        case .shift(.uppercased), .shift(.capsLocked): return ButtonColor.shiftKeyHighlightedBackgroundColor
        case .returnKey(.continue), .returnKey(.next), .returnKey(.default), .returnKey(.confirm): return ButtonColor.systemKeyBackgroundColor
        case .returnKey: return UIColor.systemBlue
        default:
            if keyCapType == .input || keyCapType == .space {
                 return ButtonColor.inputKeyBackgroundColor
            }
            return ButtonColor.systemKeyBackgroundColor
        }
    }
    
    var buttonBgHighlightedColor: UIColor? {
        switch self {
        case .shift(.uppercased), .shift(.capsLocked): return buttonBgColor
        case .space: return ButtonColor.spaceKeyHighlightedBackgroundColor
        default:
            if keyCapType == .input {
                return nil
            }
            return ButtonColor.systemHighlightedKeyBackgroundColor
        }
    }
    
    var keyCapType: KeyCapType {
        switch self {
        case "\t": return .system
        case .character, .cangjie, .contextual, .currency, .stroke, .rime: return .input
        case .space: return .space
        case .returnKey: return .returnKey
        default: return .system
        }
    }
    
    var keypadButtonBgHighlightedColor: UIColor? {
        switch self {
        case .keyboardType, .backspace, .none, .returnKey: return ButtonColor.systemHighlightedKeyBackgroundColor
        default: return ButtonColor.spaceKeyHighlightedBackgroundColor
        }
    }
    
    var buttonFgColor: UIColor {
        switch self {
        case .returnKey(.go), .returnKey(.search): return .white
        case .shift(.uppercased), .shift(.capsLocked): return ButtonColor.shiftKeyHighlightedForegroundColor
        case .returnKey(.continue), .returnKey(.next), .returnKey(.default), .returnKey(.confirm): return ButtonColor.keyForegroundColor
        case .returnKey: return .white
        default: return ButtonColor.keyForegroundColor
        }
    }
    
    var buttonHintFgColor: UIColor {
        return ButtonColor.keyHintColor
    }
    
    // TODO Return images < iOS 12
    var buttonImage: UIImage? {
        switch self {
        case .backspace: return ButtonImage.backspace
        case .nextKeyboard: return ButtonImage.globe
        case .shift(.lowercased): return ButtonImage.shift
        case .shift(.uppercased): return ButtonImage.shiftFilled
        case .shift(.capsLocked): return ButtonImage.capLockFilled
        case .dismissKeyboard: return ButtonImage.dissmissKeyboard
        // case .keyboardType(.numeric): return ButtonImage.oneTwoThree
        default: return nil
        }
    }
    
    var buttonText: String? {
        switch self {
        case .returnKey(.confirm): return LocalizedStrings.keyTitleConfirm
        case .returnKey(.go): return LocalizedStrings.keyTitleGo
        case .returnKey(.next): return LocalizedStrings.keyTitleNext
        case .returnKey(.send): return LocalizedStrings.keyTitleSend
        case .returnKey(.search), .returnKey(.google), .returnKey(.yahoo): return LocalizedStrings.keyTitleSearch
        case .returnKey(.continue): return LocalizedStrings.keyTitleContinue
        case .returnKey(.done): return LocalizedStrings.keyTitleDone
        case .returnKey(.emergencyCall): return LocalizedStrings.keyTitleSOS
        case .returnKey(.join): return LocalizedStrings.keyTitleJoin
        case .returnKey(.route): return LocalizedStrings.keyTitleRoute
        case .returnKey: return LocalizedStrings.keyTitleReturn
        case .space(.nextPage): return LocalizedStrings.keyTitleNextPage
        case .space(.select): return LocalizedStrings.keyTitleSelect
        case .space(.space): return LocalizedStrings.keyTitleSpace
        case .keyboardType(.numeric): return "123"
        case .keyboardType(.symbolic): return "#+="
        case .keyboardType(.alphabetic): return "ABC" // schema.shortName
        case .keyboardType(.numSymbolic): return ".?123"
        case .rime(.tone1, _, _): return "陰平"
        case .rime(.tone2, _, _): return "陰上"
        case .rime(.tone3, _, _): return "陰去"
        case .rime(.tone4, _, _): return "陽平"
        case .rime(.tone5, _, _): return "陽上"
        case .rime(.tone6, _, _): return "陽去"
        case .rime(.delimiter, _, _): return "分"
        case .rime(.sym, _, _): return "符"
        case .reverseLookup(let schema): return schema.signChar
        case .changeSchema(.yale): return "耶魯／劉錫祥"
        case .changeSchema(let schema): return schema.shortName
        case .toggleInputMode(.english, _): return "英文"
        case .toggleInputMode(_, let rimeSchema): return rimeSchema?.shortName
        case "'": return "′"
        case "\"": return "″"
        case "（": return "("
        case "）": return ")"
        case "「": return "「"
        case "」": return " 」"
        case "〈": return "〈　"
        case "〉": return "  〉"
        case "《": return "《　"
        case "》": return "  》"
        case "［": return "["
        case "］": return "]"
        case "｛": return "{"
        case "｝": return "}"
        case "\t": return "tab"
        case "——": return "⸻"
        case .character(let text, _, _): return text
        case .cangjie(let c, _):
            guard let asciiCode = c.lowercased().first?.asciiValue else { return nil }
            let letterIndex = Int(asciiCode - "a".first!.asciiValue!)
            return Self.cangjieKeyCaps[safe: letterIndex] ?? c
        case .stroke(let c):
            switch c.lowercased() {
            case "h": return "一"
            case "s": return "丨"
            case "p": return "丿"
            case "n": return "丶"
            case "z": return "乙"
            default: return nil
            }
        case .exportFile(let namePrefix, _): return namePrefix.capitalized
        case .currency: return SessionState.main.currencySymbol
        case .exit: return "Exit"
        default: return nil
        }
    }
    
    var buttonTitleInset: UIEdgeInsets {
        switch self {
        case .cangjie(_, true): return UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        default:
            if keyCapType == .input {
                return UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
            }
            return UIEdgeInsets.zero
        }

    }
    
    var buttonHint: String? {
        switch self {
        case .character(_, let hint, _) where hint != nil: return hint
        case .rime(_, let hint, _) where hint != nil: return hint
        case .cangjie(let c, true): return c
        case .space: return "Cantoboard"
        default: return barHint
        }
    }
    
    var barHint: String? {
        switch self {
        case "，", "。", "．", "？", "！",
             "－", "／", "：", "；", "（", "）", "＠", "、", "⋯", "⋯⋯", "＆",
             "１", "２", "３", "４", "５", "６", "７", "８", "９", "０",
             "［", "］", "｛", "｝", "＃", "％", "＾", "＊", "＋", "＝",
             "＿", "＼", "｜", "～", "〈", "＜", "＞", "〉", "《", "》",
             "＄", "￥", "「", "」", "＂", "＇": return "全"
        default: return nil
        }
    }
    
    var hasPopup: Bool {
        switch self {
        // For debugging
        case .keyboardType(.emojis): return true
        default: return self.keyCapType == .input
        }
    }
    
    private static var logsPath: String = DataFileManager.logsDirectory
    private static let userDataPath: String = DataFileManager.userDataDirectory
    
    var childrenKeyCaps: [KeyCap] {
        switch self {
        // For debugging
        case .keyboardType(.emojis): return [self, .exportFile("logs", Self.logsPath), .exportFile("user", Self.userDataPath), .exit]
        case .character(_, _, let keyCaps) where keyCaps != nil: return keyCaps!
        case .rime(_, _, let keyCaps) where keyCaps != nil: return keyCaps!
        // 123 1st row
        case "1": return ["1", "一", "壹", "１", "①", "⑴", "⒈", "❶", "㊀", "㈠"]
        case "2": return ["貳", "2", "二", "２", "②", "⑵", "⒉", "❷", "㊁", "㈡"]
        case "3": return ["③", "叁", "3", "三", "３", "⑶", "⒊", "❸", "㊂", "㈢"]
        case "4": return ["⒋", "④", "肆", "4", "四", "４", "⑷", "❹", "㊃", "㈣"]
        case "5": return ["㊄", "⒌", "⑤", "伍", "5", "五", "５", "⑸", "❺", "㈤"]
        case "6": return ["❻", "⑹", "６", "六", "6", "陸", "⑥", "⒍", "㊅", "㈥"]
        case "7": return ["⑺", "７", "七", "7", "柒", "⑦", "⒎", "❼", "㊆", "㈦"]
        case "8": return ["８", "八", "8", "捌", "⑧", "⑻", "⒏", "❽", "㊇", "㈧"]
        case "9": return ["九", "9", "玖", "９", "⑨", "⑼", "⒐", "❾", "㊈", "㈨"]
        case "0": return ["0", "０", "零", "十", "拾", "⓪", "°"]
        // 123 2nd row
        case "-": return ["-", "－", "–", "—", "•"]
        case "/": return ["/", "／", "\\"]
        case ":": return [":", "："]
        case ";": return [";", "；"]
        case "(": return ["(", "（"]
        case ")": return [")", "）"]
        case "\"": return ["\"", "＂", "”", "“", "„", "»", "«"]
        case "「": return ["「", "『", "“", "‘"]
        case "」": return ["」", "』", "”", "’"]
        // 123 3rd row
        case ".": return [".", "。", "．", "…", "⋯", "⋯⋯", "》"]
        case ",": return [",", "，", "《"]
        case "､": return ["､", "、"]
        case "&": return ["＆", "&", "§"]
        case "?": return ["?", "？", "¿"]
        case "!": return ["!", "！", "¡"]
        case "'": return ["'", "＇", "’", "‘", "`", "｀"]
        // 123 4rd row
        case "@": return ["@", "＠"]
        // #+= 1st row
        case "[": return ["[", "［", "【", "〔", "「"]
        case "]": return ["]", "］", "】", "〕", "」"]
        case "{": return ["{", "｛"]
        case "}": return ["}", "｝"]
        case "#": return ["#", "＃"]
        case "%": return ["%", "％", "‰"]
        case "^": return ["^", "＾"]
        case "*": return ["*", "＊"]
        case "+": return ["+", "＋"]
        case "=": return ["=", "≠", "≈", "＝"]
        // #+= 2nd row
        case "_": return ["_", "＿"]
        case "\\": return ["\\", "＼"]
        case "|": return ["|", "｜"]
        case "~": return ["~", "～"]
        case "<": return ["<", "〈", "＜"]
        case ">": return [">", "〉", "＞"]
        case "«": return ["«", "《"]
        case "»": return ["»", "》"]
        case "•": return ["•", "·", "．", "°"]
        // #+= 3rd row
        case "…": return ["…", "⋯"]
        // 123 1st row full width
        case "１": return ["１", "一", "壹", "1", "①", "⑴", "⒈", "❶", "㊀", "㈠"]
        case "２": return ["貳", "２", "二", "2", "②", "⑵", "⒉", "❷", "㊁", "㈡"]
        case "３": return ["③", "叁", "３", "三", "3", "⑶", "⒊", "❸", "㊂", "㈢"]
        case "４": return ["⒋", "④", "肆", "４", "四", "4", "⑷", "❹", "㊃", "㈣"]
        case "５": return ["㊄", "⒌", "⑤", "伍", "５", "五", "5", "⑸", "❺", "㈤"]
        case "６": return ["❻", "⑹", "6", "六", "６", "陸", "⑥", "⒍", "㊅", "㈥"]
        case "７": return ["⑺", "7", "七", "７", "柒", "⑦", "⒎", "❼", "㊆", "㈦"]
        case "８": return ["8", "八", "８", "捌", "⑧", "⑻", "⒏", "❽", "㊇", "㈧"]
        case "９": return ["九", "９", "玖", "9", "⑨", "⑼", "⒐", "❾", "㊈", "㈨"]
        case "０": return ["０", "0", "零", "十", "拾", "⓪", "°"]
        // 123 2nd row full width
        case "－": return ["－", "-", "–", "—", "•"]
        case "／": return ["／", "/", "\\"]
        case "：": return ["：", ":"]
        case "；": return ["；", ";"]
        case "（": return ["（", "("]
        case "）": return ["）", ")"]
        case "＂": return ["＂", "\"", "”", "“", "»", "«"]
        // 123 3rd row full width
        case "。": return ["。", ".", "．", "…", "⋯", "⋯⋯"]
        case "，": return ["，", ", "]
        case "＆": return ["&", "＆", "§"]
        case "、": return ["､", "、"]
        case "？": return ["？", "?", "¿"]
        case "！": return ["！", "!", "¡"]
        case "＇": return ["＇", "'", "’", "‘", "`", "｀"]
        // 123 4rd row full width
        case "＠": return ["＠", "@"]
        // #+= 1st row full width
        case "［": return ["［", "[", "【", "〔"]
        case "］": return ["］", "]", "】", "〕"]
        case "｛": return ["｛", "{"]
        case "｝": return ["｝", "}"]
        case "＃": return ["＃", "#"]
        case "％": return ["％", "%", "‰"]
        case "＾": return ["＾", "^"]
        case "＊": return ["＊", "*"]
        case "＋": return ["＋", "+"]
        case "＝": return ["＝", "=", "≠", "≈"]
        // #+= 2nd row full width
        case "＿": return ["＿", "_"]
        case "＼": return ["＼", "\\"]
        case "｜": return ["｜", "|"]
        case "～": return ["～", "~"]
        case "〈": return ["〈", "<", "＜"]
        case "〉": return ["〉", ">", "＞"]
        case "《": return ["《", "«"]
        case "》": return ["》", "»"]
        case "·": return ["·", "．", "•", "°"]
        // #+= 3rd row full width
        case "⋯": return ["…", "⋯"]
        case .currency:
            var currencyLists: [KeyCap] =  ["¢", "$", "€", "£", "¥", "₩", "₽", "＄", "￥"]
            let localCurrencySymbolKeyCap: KeyCap = KeyCap(SessionState.main.currencySymbol)
            currencyLists.removeAll(where: { $0 == localCurrencySymbolKeyCap })
            currencyLists.insert(localCurrencySymbolKeyCap, at: currencyLists.count / 2 - 1)
            return currencyLists
        default: return [self]
        }
    }
    
    var defaultChildKeyCapTitle: String? {
        switch self {
        case .character(".", "/", _): return nil // Contextual sym key in url mode
        default: return self.buttonText
        }
    }
    
    var keyCapCharacter: String? {
        switch self {
        case .character(let c, _, _), .cangjie(let c, _): return c.lowercased()
        default: return nil
        }
    }
    
    var isCharacter: Bool {
        switch self {
        case .character, .cangjie: return true
        default: return false
        }
    }
    
    var isContextual: Bool {
        switch self {
        case .contextual: return true
        default: return false
        }
    }
}

let FrameworkBundle = Bundle(for: KeyView.self)

class ButtonImage {
    static let globe = UIImage(named: "globe", in: Bundle(for: ButtonImage.self), with: nil)!.resizableImage(withCapInsets: .zero)
    static let backspace = UIImage(named: "delete.left", in: Bundle(for: ButtonImage.self), with: nil)!.resizableImage(withCapInsets: .zero)
    static let shift = UIImage(named: "shift", in: Bundle(for: ButtonImage.self), with: nil)!.resizableImage(withCapInsets: .zero)
    static let shiftFilled = UIImage(named: "shift.fill", in: Bundle(for: ButtonImage.self), with: nil)!.resizableImage(withCapInsets: .zero)
    static let capLockFilled = UIImage(named: "capslock.fill", in: Bundle(for: ButtonImage.self), with: nil)!.resizableImage(withCapInsets: .zero)
    static let emojiKeyboardLight = UIImage(named: "face.smiling", in: Bundle(for: ButtonImage.self), with: UIImage.SymbolConfiguration(pointSize: 18))!.resizableImage(withCapInsets: .zero)
    static let emojiKeyboardDark = UIImage(named: "face.smiling.fill", in: Bundle(for: ButtonImage.self), with: UIImage.SymbolConfiguration(pointSize: 18))!.resizableImage(withCapInsets: .zero)
    static let paneCollapseButtonImage = UIImage(named: "chevron.up", in: Bundle(for: ButtonImage.self), with: nil)!.resizableImage(withCapInsets: .zero)
    static let paneExpandButtonImage = UIImage(named: "chevron.down", in: Bundle(for: ButtonImage.self), with: nil)!.resizableImage(withCapInsets: .zero)
    static let dissmissKeyboard = UIImage(named: "keyboard.chevron.compact.down", in: Bundle(for: ButtonImage.self), with: nil)!.resizableImage(withCapInsets: .zero)
    static let clear = UIImage(named: "clear", in: Bundle(for: ButtonImage.self), with: nil)!.resizableImage(withCapInsets: .zero)
    // static let oneTwoThree = UIImage(systemName: "textformat.123", in: Bundle(for: ButtonImage.self), with: nil)
}

class ButtonColor {
    static let systemKeyBackgroundColor = UIColor(named: "systemKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let inputKeyBackgroundColor = UIColor(named: "inputKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let keyForegroundColor = UIColor(named: "keyForegroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let keyHintColor = UIColor(named: "keyHintColor", in: FrameworkBundle, compatibleWith: nil)!
    static let popupBackgroundColor = UIColor(named: "popupBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let keyShadowColor = UIColor(named: "keyShadowColor", in: FrameworkBundle, compatibleWith: nil)!
    static let shiftKeyHighlightedBackgroundColor = UIColor(named: "shiftKeyHighlightedBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let shiftKeyHighlightedForegroundColor = UIColor(named: "shiftKeyHighlightedForegroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let spaceKeyHighlightedBackgroundColor = UIColor(named: "spaceKeyHighlightedBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let systemHighlightedKeyBackgroundColor = UIColor(named: "systemHighlightedKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
}
