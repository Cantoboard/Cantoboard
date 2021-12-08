//
//  URL+Extension.swift
//  Cantoboard
//
//  Created by Alex Man on 9/12/21.
//

import UIKit
import AVFoundation

extension URL {
    var videoAspectRatio: CGFloat? {
        if let track = AVURLAsset(url: self).tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            return abs(size.width / size.height)
        }
        return nil
    }
}
