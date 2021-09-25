//
//  BaseKeyboardView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func handleKey(_ action: KeyboardAction)
    func handleInputModeList(from: UIView, with: UIEvent)
}

protocol BaseKeyboardView: UIView {
    var delegate: KeyboardViewDelegate? { get set }
    var state: KeyboardState { get set }
    func scrollCandidatePaneToNextPageInRowMode()
}
