//
//  UITableViewCell+Extension.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import UIKit

extension UITableViewCell {
    convenience init(title: String? = nil, image: UIImage? = nil) {
        self.init()
        textLabel?.text = title
        imageView?.image = image
        accessoryType = .disclosureIndicator
    }
    
    convenience init(tintedTitle: String? = nil, image: UIImage? = nil) {
        self.init(title: tintedTitle, image: image)
        textLabel?.textColor = .systemBlue
    }
}
