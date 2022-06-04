//
//  Constants.swift
//  ISEmojiView
//
//  Created by Beniamin Sarkisyan on 01/08/2018.
//

import UIKit
import Foundation

internal protocol Constants {
    var emojiSize: CGSize { get }
    var emojiFont: UIFont { get }
    var topPartSize: CGSize { get }
    var bottomPartSize: CGSize { get }
    var emojiPopViewSize: CGSize { get }
}

internal class PhoneConstants: Constants {
    let emojiSize: CGSize
    let emojiFont: UIFont
    let topPartSize: CGSize
    let bottomPartSize: CGSize
    let emojiPopViewSize: CGSize
    
    init() {
        emojiSize = CGSize(width: 45, height: 35)
        emojiFont = UIFont(name: "Apple color emoji", size: 30)!
        topPartSize = CGSize(width: emojiSize.width * 1.3, height: emojiSize.height * 1.6)
        bottomPartSize = CGSize(width: emojiSize.width * 0.8, height: emojiSize.height + 10)
        emojiPopViewSize = CGSize(width: topPartSize.width, height: topPartSize.height + bottomPartSize.height)
    }
}

internal class PadConstants: Constants {
    let emojiSize: CGSize
    let emojiFont: UIFont
    let topPartSize: CGSize
    let bottomPartSize: CGSize
    let emojiPopViewSize: CGSize
    
    init() {
        emojiSize = CGSize(width: 45 * 1.5, height: 35 * 1.5)
        emojiFont = UIFont(name: "Apple color emoji", size: 30 * 1.5)!
        topPartSize = CGSize(width: emojiSize.width * 1.3, height: emojiSize.height * 1.6)
        bottomPartSize = CGSize(width: emojiSize.width * 0.8, height: emojiSize.height + 10)
        emojiPopViewSize = CGSize(width: topPartSize.width, height: topPartSize.height + bottomPartSize.height)
    }
}

internal let CollectionMinimumLineSpacing = CGFloat(0)
internal let CollectionMinimumInteritemSpacing = CGFloat(0)

public let MaxCountOfRecentsEmojis: Int = 50
