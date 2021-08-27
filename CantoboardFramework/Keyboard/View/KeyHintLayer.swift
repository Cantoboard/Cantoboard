//
//  ButtonHintLayer.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/15/21.
//

import Foundation
import UIKit

class KeyHintLayer: CATextLayer {
    static let fontSizePerHeight: CGFloat = 10 / "＠".size(withFont: UIFont.systemFont(ofSize: 10)).height
    static let recommendedHeightRatio: CGFloat = 0.24
    
    static let buttonFloatingInsets = UIEdgeInsets(top: 0.5, left: 1, bottom: 1, right: 0.5)
    static let topRightInsets = UIEdgeInsets(top: 1.5, left: 0, bottom: 0, right: 1.5)
    
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
        contentSize = hintText.size(withFont: .systemFont(ofSize: fontSize))
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not supported.")
    }
}
