//
//  HighlightableButton.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/15/21.
//

import Foundation
import UIKit

class HighlightableButton: UIButton {
    private var originalBackgroundColor: UIColor?
    var highlightedColor: UIColor? {
        didSet {
            setupBackgroundColor()
        }
    }
    
    override var backgroundColor: UIColor? {
        get { super.backgroundColor }
        set {
            if super.backgroundColor != newValue {
                originalBackgroundColor = newValue
                setupBackgroundColor()
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            setupBackgroundColor()
        }
    }
    
    var isGrayed: Bool = false {
        didSet {
            setupBackgroundColor()
        }
    }
    
    private func setupBackgroundColor() {
        if isGrayed {
            super.backgroundColor = .systemGray
        } else if !isHighlighted {
            super.backgroundColor = originalBackgroundColor
        } else {
            super.backgroundColor = highlightedColor ?? originalBackgroundColor
        }
        layer.shadowColor = (isHighlighted && highlightedColor == ButtonColor.inputKeyHighlightedBackgroundColor ? ButtonColor.keyHighlightedShadowColor : ButtonColor.keyShadowColor).resolvedColor(with: traitCollection).cgColor
    }
    
}
