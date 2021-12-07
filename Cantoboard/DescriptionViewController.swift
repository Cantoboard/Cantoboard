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
    var option: Option!
    var stackView: UIStackView!
    var player: AVQueuePlayer!
    var playerLooper: AVPlayerLooper!
    
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
        
        let videoUrl = Bundle.main.url(forResource: "Guide/" + option.videoUrl!, withExtension: "mp4")!
        
        let playerController = AVPlayerViewController()
        let playerItem = AVPlayerItem(url: videoUrl)
        player = AVQueuePlayer(playerItem: playerItem)
        player.isMuted = true
        player.rate = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.player.rate = 1.3
        }
        playerController.player = player
        playerController.showsPlaybackControls = false
        addChild(playerController)
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        let playerView = playerController.view!
        
        let label = UILabel()
        label.text = option.description
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        
        stackView = UIStackView(arrangedSubviews: [playerView, label])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        view.addSubview(stackView)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            playerView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: 374 / 298),
            
            stackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            safeArea.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
            safeArea.centerYAnchor.constraint(equalTo: stackView.centerYAnchor)
        ])
    }
    
    @objc func dismissDescription() {
        dismiss(animated: true, completion: nil)
    }
}
