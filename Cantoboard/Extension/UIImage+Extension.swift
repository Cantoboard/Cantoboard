//
//  UIImage+Extension.swift
//  Cantoboard
//
//  Created by Alex Man on 12/8/21.
//

import Foundation
import UIKit

extension UIImage {
    func addPadding(_ padding: CGFloat) -> UIImage {
        let alignmentInset = UIEdgeInsets(top: -padding, left: -padding,
                                          bottom: -padding, right: -padding)
        return withAlignmentRectInsets(alignmentInset)
    }
}
