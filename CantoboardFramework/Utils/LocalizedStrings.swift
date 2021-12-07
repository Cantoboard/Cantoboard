//
//  LocalizedStrings.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/21/21.
//

import Foundation

class LocalizedStrings {
    private static func localizedString(_ stringKeyName: String) -> String  {
        NSLocalizedString(stringKeyName, bundle: Bundle(for: LocalizedStrings.self), comment: "Key Title of " + stringKeyName)
    }
    
    static let keyTitleNextPage = localizedString("KeyNextPage")
    static let keyTitleSelect = localizedString("KeySelect")
    static let keyTitleSpace = localizedString("KeySpace")
    static let keyTitleFullWidthSpace = localizedString("KeyFullWidthSpace")
    static let keyTitleConfirm = localizedString("KeyConfirm")
    static let keyTitleGo = localizedString("KeyGo")
    static let keyTitleNext = localizedString("KeyNext")
    static let keyTitleSend = localizedString("KeySend")
    static let keyTitleSearch = localizedString("KeySearch")
    static let keyTitleContinue = localizedString("KeyContinue")
    static let keyTitleDone = localizedString("KeyDone")
    static let keyTitleSOS = localizedString("KeySOS")
    static let keyTitleJoin = localizedString("KeyJoin")
    static let keyTitleRoute = localizedString("KeyRoute")
    static let keyTitleReturn = localizedString("KeyReturn")
}
