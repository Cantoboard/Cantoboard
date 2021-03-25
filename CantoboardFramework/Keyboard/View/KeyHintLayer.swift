//
//  ButtonHintLayer.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/15/21.
//

import Foundation
import UIKit

class KeyHintLayer: CATextLayer {
    private var parentInsets = UIEdgeInsets.zero
    
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
    }
    
    func setup(keyCap: KeyCap, hintText: String, parentInsets: UIEdgeInsets = UIEdgeInsets(top: 2, left: 2.5, bottom: 2, right: 2.5)) {
        string = hintText
        font = keyCap.buttonFont
        fontSize = keyCap.buttonHintFontSize
        self.parentInsets = parentInsets
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
        frame = CGRect(origin: CGPoint(x: superlayer.bounds.width - size.width - parentInsets.right, y: parentInsets.top), size: size)
    }
}
