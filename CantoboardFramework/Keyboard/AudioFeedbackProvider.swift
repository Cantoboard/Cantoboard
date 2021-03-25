//
//  AudioFeedbackProvider.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/10/21.
//

import Foundation
import AudioToolbox
import UIKit

class AudioFeedbackProvider {
    private static let ClickPress: SystemSoundID = 1123
    private static let DeletePress: SystemSoundID = 1155
    private static let ModifierPress: SystemSoundID = 1156

    static func Play(keyboardAction: KeyboardAction) {
        switch keyboardAction {
        case .character(_), .rime(_), .emoji(_):
            // UIDevice.current.playInputClick()
            AudioServicesPlaySystemSound(Self.ClickPress)
        case .backspace, .deleteWord:
            AudioServicesPlaySystemSound(Self.DeletePress)
        case .keyboardType(_), .space, .newLine:
            AudioServicesPlaySystemSound(Self.ModifierPress)
        default: ()
        }
    }
}
