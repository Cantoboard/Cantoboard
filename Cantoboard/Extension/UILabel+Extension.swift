//
//  UILabel+Extension.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import UIKit

extension UILabel {
    convenience init(title: String) {
        self.init()
        text = title
        font = .preferredFont(forTextStyle: .body)
    }
    
    convenience init(tintedTitle: String) {
        self.init(title: tintedTitle)
        textColor = .systemBlue
    }
}
