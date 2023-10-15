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
    case fullWidthSpace = "fullWidthSpace"
    case select = "select"
    case nextPage = "next page"
    
    var isSpace: Bool {
        switch self {
        case .space, .fullWidthSpace: return true
        default: return false
        }
    }
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
    case url
    case character(String)
    
    public init(stringLiteral value: String) {
        self = .character(value)
    }
}

struct KeyCapHints: Equatable {
    let leftHint, rightHint, bottomHint: String?
    
    public init(rightHint: String) {
        self.init(leftHint: nil, rightHint: rightHint, bottomHint: nil)
    }
    
    public init(leftHint: String? = nil, rightHint: String? = nil, bottomHint: String? = nil) {
        self.leftHint = leftHint
        self.rightHint = rightHint
        self.bottomHint = bottomHint
    }
}

indirect enum KeyCap: Equatable, ExpressibleByStringLiteral {
    case
    none,
    backspace,
    toggleInputMode(/* toMode */ InputMode, RimeSchema?, /* hasHint */ Bool),
    toggleCharForm(CharForm),
    character(String, KeyCapHints?, /* children key caps */ [KeyCap]?),
    cangjie(String, KeyCapHints?, /* children key caps */ [KeyCap]?, CangjieKeyCapMode),
    stroke(String),
    jyutPing10Keys(String),
    selectRomanization,
    emoji(String),
    keyboardType(KeyboardType),
    returnKey(ReturnKeyType),
    nextKeyboard,
    space(SpaceKeyMode),
    shift(_ state: KeyboardShiftState),
    rime(RimeChar, KeyCapHints?, /* children key caps */ [KeyCap]?),
    contextual(ContextualKey),
    reverseLookup(RimeSchema),
    changeSchema(RimeSchema),
    exportFile(String, String),
    singleQuote,
    doubleQuote,
    currency,
    dismissKeyboard,
    exit,
    placeholder(KeyCap),
    combo(/* Combo keycaps */ [String]), // e.g. combo(["A", "B"]) click once to insert A, click twice to replace A with B.
    keypadRimeDelimiter
    
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
        case .toggleInputMode(let toInputMode, _, _): return .toggleInputMode(toInputMode)
        case .character(let c, _, _): return .character(c)
        case .cangjie(let c, _, _, _): return .character(c)
        case .stroke(let c), .jyutPing10Keys(let c): return .character(c)
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
        case .singleQuote: return .quote(false)
        case .doubleQuote: return .quote(true)
        case .dismissKeyboard: return .dismissKeyboard
        case .combo: return .none // Dynamically evaluated in KeyView.
        case .keypadRimeDelimiter: return .rime(.delimiter)
        case .selectRomanization: return .toggleTenKeysSpecialization
        case .toggleCharForm(let cf): return .setCharForm(cf)
        default: return .none
        }
    }
    
    var character: Character? {
        switch self {
        case .character(let c, _, _): return c.first ?? nil
        default: return nil
        }
    }
    
    var buttonBgColor: UIColor {
        switch self {
        case .shift(.uppercased), .shift(.capsLocked): return ButtonColor.shiftKeyHighlightedBackgroundColor
        case .returnKey(.continue), .returnKey(.next), .returnKey(.default), .returnKey(.confirm): return ButtonColor.systemKeyBackgroundColor
        case .returnKey: return UIColor.systemBlue
        case _ where keyCapType == .input || keyCapType == .space: return ButtonColor.inputKeyBackgroundColor
        default: return ButtonColor.systemKeyBackgroundColor
        }
    }
    
    var buttonBgHighlightedColor: UIColor {
        switch self {
        case .shift(.uppercased), .shift(.capsLocked): return buttonBgColor
        case _ where keyCapType == .input || keyCapType == .space: return ButtonColor.inputKeyHighlightedBackgroundColor
        default: return ButtonColor.systemKeyHighlightedBackgroundColor
        }
    }
    
    var buttonBgHighlightedShadowColor: UIColor {
        switch keyCapType {
        case .input, .space: return ButtonColor.keyHighlightedShadowColor
        default: return ButtonColor.keyShadowColor
        }
    }
    
    var keyCapType: KeyCapType {
        switch self {
        case "\t": return .system
        case .character, .cangjie, .contextual, .currency, .singleQuote, .doubleQuote, .stroke, .jyutPing10Keys, .rime, .combo: return .input
        case .space: return .space
        case .returnKey: return .returnKey
        default: return .system
        }
    }
    
    var keypadButtonBgHighlightedColor: UIColor {
        switch self {
        case .keyboardType, .backspace, .none, .returnKey: return ButtonColor.systemKeyHighlightedBackgroundColor
        default: return ButtonColor.inputKeyHighlightedBackgroundColor
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
        case "\t": return ButtonImage.tab
        case .backspace: return ButtonImage.backspace
        case .nextKeyboard: return ButtonImage.globe
        case .shift(.lowercased): return ButtonImage.shift
        case .shift(.uppercased): return ButtonImage.shiftFilled
        case .shift(.capsLocked): return ButtonImage.capLockFilled
        case .dismissKeyboard: return ButtonImage.dismissKeyboard
        case .keyboardType(.emojis): return ButtonImage.emojiKeyboardLight
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
        case .space(.fullWidthSpace): return LocalizedStrings.keyTitleFullWidthSpace
        case .keyboardType(.numeric): return "123"
        case .keyboardType(.symbolic): return "#+="
        case .keyboardType(.alphabetic): return "ABC"
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
        case .changeSchema(.jyutping10keys): return "九宮格粵拼"
        case .changeSchema(let schema): return schema.shortName
        case .toggleInputMode(.english, _, _): return "英文"
        case .toggleInputMode(_, let rimeSchema, _): return rimeSchema?.shortName
        case .toggleCharForm(let charForm): return charForm.caption
        case .singleQuote: return "′"
        case .doubleQuote: return "″"
        case "（": return "（⠀"
        case "）": return "⠀）"
        case "「": return "「⠀"
        case "」": return "⠀」"
        case "『": return "『⠀"
        case "』": return "⠀』"
        case "〈": return "〈⠀"
        case "〉": return "⠀〉"
        case "《": return "《⠀"
        case "》": return "⠀》"
        case "［": return "［⠀"
        case "］": return "⠀］"
        case "｛": return "｛⠀"
        case "｝": return "⠀｝"
        case "【": return "【⠀"
        case "】": return "⠀】"
        case "\t": return nil
        case "——": return "⸻"
        case .character(let text, _, _): return text
        case .cangjie(let letter, _, _, let cangjieKeyCapMode): return cangjieKeyCapMode == .cangjieRoot ? CangjieConstants.cangjieKeyCaps(letter) : letter
        case .stroke(let c):
            switch c.lowercased() {
            case "h": return "一"
            case "s": return "丨"
            case "p": return "丿"
            case "n": return "丶"
            case "z": return "乛"
            default: return nil
            }
        case .jyutPing10Keys(let c):
            switch c {
            case "A": return "A B C"
            case "D": return "D E F"
            case "G": return "G H I"
            case "J": return "J K L"
            case "M": return "M N O"
            case "P": return "P Q R S"
            case "T": return "T U V"
            case "W": return "W X Y Z"
            default: return nil
            }
        case .selectRomanization: return "選拼音"
        case .exportFile(let namePrefix, _): return namePrefix.capitalized
        case .currency: return SessionState.main.currencySymbol
        case .exit: return "Exit"
        case .combo(let items): return items.joined()
        case .keypadRimeDelimiter: return "分隔"
        default: return nil
        }
    }
    
    var buttonTitleInset: UIEdgeInsets {
        switch self {
        case .cangjie(_, let hints, _, _) where hints != nil: return UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        case _ where keyCapType == .input: return UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
        default: return .zero
        }
    }
    
    var buttonLeftHint: String? {
        switch self {
        case .character(_, let hints, _), .rime(_, let hints, _), .cangjie(_, let hints, _, _): return hints?.leftHint
        case .toggleInputMode(_, _, let hasHint): return hasHint ? SessionState.main.lastCharForm.caption : nil
        default: return nil
        }
    }
    
    var buttonRightHint: String? {
        switch self {
        case .character(_, let hint, _), .rime(_, let hint, _): return hint?.rightHint ?? barHint
        case .cangjie(_, let hint, _, let cangjieKeyCapMode):
            let rightHint = hint?.rightHint ?? barHint
            return cangjieKeyCapMode == .cangjieRoot ? rightHint : CangjieConstants.cangjieKeyCaps(hint?.rightHint ?? "")
        case .space: return "Cantoboard"
        default: return barHint
        }
    }
    
    var buttonBottomHint: String? {
        switch self {
        case .character(_, let hints, _), .rime(_, let hints, _), .cangjie(_, let hints, _, _): return hints?.bottomHint
        default: return nil
        }
    }
    
    var barHint: String? {
        switch self {
        case "，", "。", "．", "？", "！",
             "－", "／", "：", "；", "（", "）", "＠", "、", "⋯", "⋯⋯", "＆",
             "１", "２", "３", "４", "５", "６", "７", "８", "９", "０",
             "［", "］", "｛", "｝", "＃", "％", "＾", "＊", "＋", "＝",
             "＿", "＼", "｜", "～", "〈", "＜", "＞", "〉",
             "＄", "＂", "＇": return "全"
        default: return nil
        }
    }
    
    var hasPopup: Bool {
        switch self {
        // For debugging
        case .keyboardType(.emojis): return true
        case .toggleInputMode(_, _, _): return true
        default: return keyCapType == .input
        }
    }
    
    private static var logsPath: String = DataFileManager.logsDirectory
    private static let userDataPath: String = DataFileManager.userDataDirectory
    private static let tmpPath: String = FileManager.default.temporaryDirectory.path
    
    var withoutHints: KeyCap {
        switch self {
        case .character(let c, _, _): return KeyCap(c)
        case .toggleInputMode(let im, let rs, _): return .toggleInputMode(im, rs, false)
        // case .cangjie(let c, _): return .cangjie(c, false)
        default: return self
        }
    }
    
    var childrenKeyCaps: [KeyCap] {
        switch self {
        // For debugging
        case .keyboardType(.emojis): return [self, .exportFile("logs", Self.logsPath), .exportFile("user", Self.userDataPath), .exportFile("rime", Self.tmpPath), .exit]
        case .toggleInputMode(_, _, _): return [KeyCap.getToggleCharForm(), self.withoutHints]
        case .character(_, _, let keyCaps) where keyCaps != nil: return keyCaps!
        case .cangjie(_, _, let keyCaps, _) where keyCaps != nil: return keyCaps!
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
        case "/": return ["/", "／", "\\", "÷"]
        case ":": return [":", "："]
        case ";": return [";", "；"]
        case "(": return ["(", "（"]
        case ")": return [")", "）"]
        case .doubleQuote: return ["\"", "＂", "”", "“", "„", "»", "«"]
        case "「": return ["「", "『", "“", "‘", "｢"]
        case "」": return ["」", "』", "”", "’", "｣"]
        // 123 3rd row
        case ".": return [".", "。", "．", "…", "⋯", "⋯⋯"]
        case ",": return [",", "，"]
        case "､": return ["､", "、"]
        case "^_^": return ["^_^", "^‿^", ">_<"]
        case "?": return ["?", "？", "¿"]
        case "!": return ["!", "！", "¡"]
        case .singleQuote: return ["'", "＇", "’", "‘", "`", "｀"]
        // 123 4rd row
        case "@": return ["@", "＠"]
        // #+= 1st row
        case "[": return ["[", "［", "【", "〔", "「"]
        case "]": return ["]", "］", "】", "〕", "」"]
        case "{": return ["{", "｛"]
        case "}": return ["}", "｝"]
        case "#": return ["#", "＃"]
        case "%": return ["%", "％", "‰"]
        case "^": return ["^", "＾", "↑", "↓"]
        case "*": return ["*", "＊", "×"]
        case "+": return ["+", "＋"]
        case "=": return ["=", "≠", "≈", "＝"]
        // #+= 2nd row
        case "_": return ["_", "＿"]
        case "\\": return ["\\", "＼"]
        case "|": return ["|", "｜"]
        case "~": return ["~", "～"]
        case "<": return ["<", "〈", "＜", "←"]
        case ">": return [">", "〉", "＞", "→"]
        case "«": return ["«", "《", "⇔"]
        case "»": return ["»", "》", "⇒"]
        case "&": return ["＆", "&", "§"]
        case "•": return ["•", "·", "．", "°"]
        // #+= 4th row
        case "…": return ["…", "⋯"]
        // 123 2nd row full width
        case "—": return ["—", "–", "-", "－", "·"]
        case "／": return ["／", "/", "\\", "÷"]
        case "：": return ["：", ":"]
        case "；": return ["；", ";"]
        case "（": return ["（", "("]
        case "）": return ["）", ")"]
        // 123 3rd row full width
        case "。": return ["。", ".", "．", "…", "⋯", "⋯⋯"]
        case "，": return ["，", ", "]
        case "、": return ["､", "、"]
        case "？": return ["？", "?", "¿"]
        case "！": return ["！", "!", "¡"]
        // #+= 1st row full width
        case "［": return ["［", "[", "【", "〔"]
        case "］": return ["］", "]", "】", "〕"]
        case "｛": return ["｛", "{"]
        case "｝": return ["｝", "}"]
        // #+= 2nd row full width
        case "＼": return ["＼", "\\"]
        case "｜": return ["｜", "|"]
        case "～": return ["～", "~"]
        case "〈": return ["〈", "<", "＜", "←"]
        case "〉": return ["〉", ">", "＞", "→"]
        case "《": return ["《", "«", "⇔"]
        case "》": return ["》", "»", "⇒"]
        case "·": return ["·", "．", "•", "°"]
        // #+= 4th row full width
        case "⋯": return ["…", "⋯"]
        case .currency:
            var currencyLists: [KeyCap] =  ["¢", "$", "€", "£", "¥", "₩", "₽", "＄"]
            let localCurrencySymbolKeyCap: KeyCap = KeyCap(SessionState.main.currencySymbol)
            currencyLists.removeAll(where: { $0 == localCurrencySymbolKeyCap })
            currencyLists.insert(localCurrencySymbolKeyCap, at: currencyLists.count / 2 - 1)
            return currencyLists
        case "'": return ["'", "＇"]
        case "\"": return ["\"", "＂"]
        case "a": return [self, "à", "á", "â", "ä", "æ", "ã", "å", "ā"]
        case "c": return [self, "ç", "ć", "č"]
        case "e": return [self, "è", "é", "ê", "ë", "ē", "ė", "ę"]
        case "i": return [self, "î", "ï", "í", "ī", "į", "ì"]
        case "l": return [self, "ł"]
        case "m": return [self, "m̀", "ḿ"]
        case "n": return [self, "ñ", "ń"]
        case "o": return [self, "ô", "ö", "ò", "ó", "œ", "ø", "ō", "õ"]
        case "s": return [self, "ß", "ś", "š"]
        case "u": return [self, "û", "ü", "ù", "ú", "ū"]
        case "y": return [self, "ÿ"]
        case "z": return [self, "ž", "ź", "ż"]
        case "A": return [self, "À", "Á", "Â", "Ä", "Æ", "Ã", "Å", "Ā"]
        case "C": return [self, "Ç", "Ć", "Č"]
        case "E": return [self, "È", "É", "Ê", "Ë", "Ē", "Ė", "Ę"]
        case "I": return [self, "Î", "Ï", "Í", "Ī", "Į", "Ì"]
        case "L": return [self, "Ł"]
        case "M": return [self, "M̀", "Ḿ"]
        case "N": return [self, "Ñ", "Ń"]
        case "O": return [self, "Ô", "Ö", "Ò", "Ó", "Œ", "Ø", "Ō", "Õ"]
        case "S": return [self, "Ś", "Š"]
        case "U": return [self, "Û", "Ü", "Ù", "Ú", "Ū"]
        case "Y": return [self, "Ÿ"]
        case "Z": return [self, "Ž", "Ź", "Ż"]
        default: return [self]
        }
    }
    
    var defaultChildKeyCapTitle: String? {
        switch self {
        case .character(",", KeyCapHints(rightHint: "符"), _): return "." // Contextual sym key in English mode
        case .character("，", KeyCapHints(rightHint: "符"), _): return "。" // Contextual sym key in Chinese mode
        case .character(".", KeyCapHints(rightHint: "/"), _): return nil // Contextual sym key in url mode
        case .toggleInputMode(_, _, _): return KeyCap.getToggleCharForm().buttonText
        default: return self.buttonText
        }
    }
    
    var isCombo: Bool {
        switch self {
        case .combo: return true
        default: return false
        }
    }
    
    var isContextual: Bool {
        switch self {
        case .contextual: return true
        default: return false
        }
    }
    
    var isKeyboardType: Bool {
        switch self {
        case .keyboardType: return true
        default: return false
        }
    }
    
    var isPlaceholder: Bool {
        switch self {
        case .placeholder: return true
        default: return false
        }
    }
    
    var isRimeTone: Bool {
        switch self {
        case .rime(let rc, _, _):
            return rc == .tone1 || rc == .tone2 || rc == .tone3 ||
                   rc == .tone4 || rc == .tone5 || rc == .tone6
        default: ()
        }
        return false
    }
    
    var unescaped: KeyCap {
        switch self {
        case .placeholder(let keyCap): return keyCap.unescaped
        default: return self
        }
    }
    
    private var toSpecialSymbol: SpecialSymbol? {
        for specialSymbol in SpecialSymbol.allCases {
            if specialSymbol.keyCaps.contains(self) {
                return specialSymbol
            }
        }
        return nil
    }
    
    func symbolTransform(state: KeyboardState) -> KeyCap {
        guard state.symbolShapeOverride == nil else { return self }
        if let specialSymbol = self.toSpecialSymbol {
            return specialSymbol.transform(keyCap: self, state: state)
        }
        return self
    }
    
    static func getToggleCharForm() -> KeyCap {
        switch SessionState.main.lastCharForm {
        case .traditional: return .toggleCharForm(.simplified)
        case .simplified: return .toggleCharForm(.traditional)
        }
    }
}

enum SpecialSymbol: CaseIterable {
    case colon, dot, minus, slash,
         parenthesis, curlyBracket, squareBracket, angleBracket, doubleAngleBracket
    
    var keyCapPairs: [(half: KeyCap, full: KeyCap)] {
        switch self {
        case .colon: return [(half: ":", full: "：")]
        case .dot: return [(half: ".", full: "。")]
        case .minus: return [(half: "-", full: "—")]
        case .slash: return [(half: "/", full: "／")]
        case .parenthesis: return [(half: "(", full: "（"), (half: ")", full: "）")]
        case .curlyBracket: return [(half: "{", full: "｛"), (half: "}", full: "｝")]
        case .squareBracket: return [(half: "[", full: "［"), (half: "]", full: "］")]
        case .angleBracket: return [(half: "<", full: "〈"), (half: ">", full: "〉")]
        case .doubleAngleBracket: return [(half: "«", full: "《"), (half: "»", full: "》")]
        }
    }
    
    var keyCaps: [KeyCap] {
        return keyCapPairs.flatMap { return [$0.half, $0.full] }
    }
    
    func transform(keyCap: KeyCap, state: KeyboardState) -> KeyCap {
        let matchingKeyCap = keyCapPairs.first(where: { $0.half == keyCap || $0.full == keyCap })
        guard let matchingKeyCap = matchingKeyCap else { return keyCap }
        
        let shapeOverride = state.specialSymbolShapeOverride[self]
        
        switch shapeOverride {
        case .half: return matchingKeyCap.half
        case .full: return matchingKeyCap.full
        default: return keyCap
        }
    }
    
    func determineSymbolShape(textBefore: String) -> SymbolShape? {
        let symbolShape = Settings.cached.symbolShape
        switch symbolShape {
        case .smart:
            switch self {
            case .colon, .dot, .minus, .slash: return Self.determineSymbolShapeFromLastChar(textBefore: textBefore)
            case .parenthesis, .curlyBracket, .squareBracket, .angleBracket, .doubleAngleBracket:
                return determineSymbolShapeFromLastMatchingChar(textBefore: textBefore)
            }
        case .half: return .half
        case .full: return .full
        }
    }
    
    private static func determineSymbolShapeFromLastChar(textBefore: String) -> SymbolShape? {
        for c in textBefore.reversed() {
            if c.isEnglishLetterOrDigit {
                return .half
            } else if c.isChineseChar {
                return .full
            }
        }
        
        return nil
    }
    
    private func determineSymbolShapeFromLastMatchingChar(textBefore: String) -> SymbolShape? {
        let halfChars = keyCapPairs.compactMap { $0.half.character }
        let fullChars = keyCapPairs.compactMap { $0.full.character }
        
        for c in textBefore.reversed() {
            if halfChars.contains(c) {
                return .half
            } else if fullChars.contains(c) {
                return .full
            }
        }
        
        return nil
    }
}

let FrameworkBundle = Bundle(for: KeyView.self)

class ButtonImage {
    private static func imageAssets(_ key: String) -> UIImage {
        let config = UIImage.SymbolConfiguration(weight: .light)
        let image = UIImage(systemName: key) ?? UIImage(named: key, in: Bundle(for: ButtonImage.self), with: nil)!
        return image.applyingSymbolConfiguration(config)!
    }
    
    static let globe = imageAssets("globe")
    static let backspace = imageAssets("delete.left")
    static let backspaceFilled = imageAssets("delete.left.fill")
    static let shift = imageAssets("shift")
    static let shiftFilled = imageAssets("shift.fill")
    static let capLockFilled = imageAssets("capslock.fill")
    static let emojiKeyboardLight = imageAssets("face.smiling")
    static let emojiKeyboardDark = imageAssets("face.smiling.fill")
    static let paneCollapseButtonImage = imageAssets("chevron.up")
    static let paneExpandButtonImage = imageAssets("chevron.down")
    static let paneScrollRightButtonImage = imageAssets("arrow.right")
    static let paneScrollToBeginningButtonImage = imageAssets("return.left")
    static let paneScrollUpButtonImage = imageAssets("triangle.up")
    static let paneScrollDownButtonImage = imageAssets("triangle.down")
    
    static let dismissKeyboard = imageAssets("keyboard.chevron.compact.down")
    static let clear = imageAssets("clear")
    static let clearFilled = imageAssets("clear.fill")
    static let tab = imageAssets("arrow.right.to.line")
    static let returnKey = imageAssets("return.left")
}

class ButtonColor {
    private static func colorAssets(_ key: String) -> UIColor {
        UIColor(named: key, in: FrameworkBundle, compatibleWith: nil)!
    }
    
    static let systemKeyBackgroundColor = colorAssets("systemKeyBackgroundColor")
    static let inputKeyBackgroundColor = colorAssets("inputKeyBackgroundColor")
    static let keyForegroundColor = colorAssets("keyForegroundColor")
    static let keyHintColor = colorAssets("keyHintColor")
    static let popupBackgroundColor = colorAssets("popupBackgroundColor")
    static let keyShadowColor = colorAssets("keyShadowColor")
    static let keyHighlightedShadowColor = colorAssets("keyHighlightedShadowColor")
    static let keyGrayedColor = colorAssets("keyGrayedColor")
    static let shiftKeyHighlightedBackgroundColor = colorAssets("shiftKeyHighlightedBackgroundColor")
    static let shiftKeyHighlightedForegroundColor = colorAssets("shiftKeyHighlightedForegroundColor")
    static let inputKeyHighlightedBackgroundColor = colorAssets("inputKeyHighlightedBackgroundColor")
    static let systemKeyHighlightedBackgroundColor = colorAssets("systemKeyHighlightedBackgroundColor")
    static let placeholderKeyForegroundColor = colorAssets("placeholderKeyForegroundColor")
}
