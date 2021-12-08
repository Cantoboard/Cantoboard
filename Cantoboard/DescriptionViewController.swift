//
//  DescriptionViewController.swift
//  Cantoboard
//
//  Created by Alex Man on 23/11/21.
//

import UIKit
import AVFoundation
import AVKit

class DescriptionViewController: UIViewController {
    static let videoAspectRatio: CGFloat = 374 / 298
    static let stackViewInset = UIEdgeInsets(top: 10, left: 0, bottom: 15, right: 0)
    static let paddingBetweenTitleAndDescription: CGFloat = 10
    
    var option: Option!
    var stackView: UIStackView!
    var playerView: UIView?
    var playerLooper: AVPlayerLooper?
    
    convenience init(option: Option) {
        self.init()
        self.option = option
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleLabel = UILabel()
        titleLabel.text = option.title
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissDescription))
        view.backgroundColor = .systemBackground
        
        if let videoUrl = option.videoUrl {
            let videoUrl = Bundle.main.url(forResource: "Guide/" + videoUrl, withExtension: "mp4")!
            
            let playerController = AVPlayerViewController()
            let playerItem = AVPlayerItem(url: videoUrl)
            let player = AVQueuePlayer(playerItem: playerItem)
            player.isMuted = true
            player.rate = 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak player] in
                player?.rate = 1.3
            }
            playerController.player = player
            playerController.showsPlaybackControls = false
            addChild(playerController)
            playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
            playerView = playerController.view
            playerView?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let label = UILabel()
        label.text = option.description
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        stackView = UIStackView(arrangedSubviews: [playerView, label].compactMap {$0})
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20
        view.addSubview(stackView)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -Self.stackViewInset.bottom),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: Self.stackViewInset.top),
            label.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
        
        if let playerView = playerView {            
            let leadingConstraint = playerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)
            leadingConstraint.priority = .defaultLow
            
            let trailingConstraint = playerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            trailingConstraint.priority = .defaultLow
            
            NSLayoutConstraint.activate([
                leadingConstraint, trailingConstraint,
                playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 1 / Self.videoAspectRatio)
            ])
        }
    }
    
    @objc func dismissDescription() {
        dismiss(animated: true, completion: nil)
    }
}
