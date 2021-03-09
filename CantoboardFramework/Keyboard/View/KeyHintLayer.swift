//
//  ButtonHintLayer.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/15/21.
//

import Foundation
import UIKit

class KeyHintLayer: CATextLayer {
    override init() {
        super.init()
        
        let newActions = [
            "onOrderIn": NSNull(),
            "onOrderOut": NSNull(),
            "sublayers": NSNull(),
            "contents": NSNull(),
            "position": NSNull(),
            "bounds": NSNull(),
            "hidden": NSNull(),
            "fontSize": NSNull(),
        ]
        actions = newActions
        
        alignmentMode = .right
        allowsFontSubpixelQuantization = true
        contentsScale = UIScreen.main.scale
        fontSize = 9
    }
    
    func setup(_ keyCap: KeyCap, _ hintText: String) {
        string = hintText
        font = keyCap.buttonFont

    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not supported.")
    }
    
    func layout() {
        guard let font = font as? UIFont,
              let superlayer = superlayer,
              let string = string as? NSString else { return }
        
        let size = string.size(withAttributes: [.font: font.withSize(fontSize)])
        frame = CGRect(origin: CGPoint(x: superlayer.bounds.width - 2 - size.width, y: 2), size: size)
    }
}
