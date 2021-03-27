//
//  String+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/27/21.
//

import Foundation
import UIKit

extension String {
    func size(withFont: UIFont) -> CGSize {
        return (self as NSString).size(withAttributes: [NSAttributedString.Key.font: withFont])
    }
}
