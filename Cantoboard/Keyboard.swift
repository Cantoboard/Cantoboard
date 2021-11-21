//
//  Keyboard.swift
//  Cantoboard
//
//  Created by Alex Man on 23/11/21.
//

import Foundation

class Keyboard {
    static var isEnabled: Bool {
        guard let keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String],
              let bundleIdentifier = Bundle.main.bundleIdentifier else { return false }
        return keyboards.contains(bundleIdentifier + ".CantoboardExtension")
    }
}
