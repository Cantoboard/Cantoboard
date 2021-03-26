//
//  ButtonHintLayer.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/15/21.
//

import Foundation
import UIKit

class KeyHintLayer: CATextLayer {
    static let buttonInsets = UIEdgeInsets(top: 2, left: 2.5, bottom: 2, right: 2.5)
    
    private var contentSize: CGSize = .zero
    
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
    
    func setup(keyCap: KeyCap, hintText: String) {
        string = hintText
        font = keyCap.buttonFont
        fontSize = keyCap.buttonHintFontSize
        contentSize = (hintText as NSString).size(withAttributes: [.font: keyCap.buttonFont.withSize(keyCap.buttonHintFontSize)])
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not supported.")
    }
    
    func layout(insets: UIEdgeInsets) {
        guard let superlayer = superlayer else { return }
        frame = CGRect(origin: CGPoint(x: superlayer.bounds.width - contentSize.width - insets.right, y: insets.top), size: contentSize)
    }
}
