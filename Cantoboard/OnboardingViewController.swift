//
//  OnboardingViewController.swift
//  Cantoboard
//
//  Created by Alex Man on 16/11/21.
//

import UIKit
import AVFoundation
import AVKit

private struct Page {
    let video: String
    let heading: String
    let content: String
    let buttonTitle: String?
    let buttonAction: Selector?
    let footnote: String?
    
    init(_ video: String, _ heading: String, _ content: String, footnote: String? = nil) {
        self.video = video
        self.heading = heading
        self.content = content
        self.buttonTitle = nil
        self.buttonAction = nil
        self.footnote = footnote
    }
    
    init(_ video: String, _ heading: String, _ content: String, buttonTitle: String, buttonAction: Selector, footnote: String? = nil) {
        self.video = video
        self.heading = heading
        self.content = content
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.footnote = footnote
    }
}

class HighlightableButton: UIButton {
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .systemBlue.withAlphaComponent(0.75) : .systemBlue
        }
    }
}

class OnboardingViewController: UIViewController, UIScrollViewDelegate {
    var outerStackView: UIStackView!
    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    
    var pages: [UIView]!
    var previousPage: Int?
    
    var players: [AVQueuePlayer]!
    var playerLoopers: [AVPlayerLooper]!
    
    private static let pages: [Page] = [
        Page("Guide1-1", LocalizedStrings.onboarding_0_heading, LocalizedStrings.onboarding_0_content),
        Page("Guide4-1", LocalizedStrings.onboarding_1_heading, LocalizedStrings.onboarding_1_content),
        Page("Guide5-1", LocalizedStrings.onboarding_2_heading, LocalizedStrings.onboarding_2_content),
        Page("Guide6-1", LocalizedStrings.onboarding_3_heading, LocalizedStrings.onboarding_3_content),
        Page("Guide11-1", LocalizedStrings.onboarding_4_heading, LocalizedStrings.onboarding_4_content),
        Page("Guide11-2", LocalizedStrings.onboarding_5_heading, LocalizedStrings.onboarding_5_content,
             buttonTitle: LocalizedStrings.onboarding_jumpToSettings, buttonAction: #selector(jumpToSettings), footnote: LocalizedStrings.onboarding_5_footnote),
        Page("Guide1-2", LocalizedStrings.onboarding_5_installed_heading, LocalizedStrings.onboarding_5_installed_content,
             buttonTitle: LocalizedStrings.onboarding_done, buttonAction: #selector(endOnboarding)),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navTitle = UILabel()
        navTitle.text = "Cantoboard"
        navTitle.font = .systemFont(ofSize: 26, weight: .semibold)
        
        let navImageView = UIImageView(image: UIImage(named: "AppIcon60x60"))
        navImageView.layer.cornerRadius = 8
        navImageView.clipsToBounds = true
        navImageView.widthAnchor.constraint(equalTo: navImageView.heightAnchor).isActive = true
        
        let navStackView = UIStackView(arrangedSubviews: [navImageView, navTitle])
        navStackView.translatesAutoresizingMaskIntoConstraints = false
        navStackView.spacing = 12
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navStackView)
        
        let skipButtonItem = UIBarButtonItem(title: LocalizedStrings.onboarding_skip, style: .plain, target: self, action: #selector(endOnboarding))
        skipButtonItem.tintColor = .label
        navigationItem.rightBarButtonItem = skipButtonItem
        
        // view.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1)
        view.backgroundColor = .systemBackground
        
        // view -> scrollView -> outerView -> outerStackView -> (innerView -> innerStackView) * items.count
        
        players = []
        playerLoopers = []
        pages = Self.pages.map { page in
            let videoUrl = Bundle.main.url(forResource: "Guide/" + page.video, withExtension: "mp4")!
            
            let playerController = AVPlayerViewController()
            let playerItem = AVPlayerItem(url: videoUrl)
            let player = AVQueuePlayer(playerItem: playerItem)
            player.isMuted = true
            playerController.player = player
            playerController.showsPlaybackControls = false
            addChild(playerController)
            players.append(player)
            playerLoopers.append(AVPlayerLooper(player: player, templateItem: playerItem)) // prevent garbage collection
            let playerView = playerController.view!
            
            let headingLabel = UILabel()
            headingLabel.text = page.heading
            headingLabel.font = .systemFont(ofSize: 28, weight: .medium)
            headingLabel.numberOfLines = 0
            
            let contentLabel = UILabel()
            contentLabel.font = .systemFont(ofSize: 20, weight: .light)
            contentLabel.numberOfLines = 0
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            // paragraphStyle.alignment = .justified
            contentLabel.attributedText = NSMutableAttributedString(string: page.content, attributes: [.paragraphStyle: paragraphStyle])
            
            let innerStackView = UIStackView(arrangedSubviews: [playerView, headingLabel, contentLabel])
            innerStackView.translatesAutoresizingMaskIntoConstraints = false
            innerStackView.axis = .vertical
            innerStackView.spacing = 30
            
            if let footnote = page.footnote {
                let footnoteLabel = UILabel()
                footnoteLabel.text = footnote
                footnoteLabel.font = .preferredFont(forTextStyle: .footnote)
                footnoteLabel.numberOfLines = 0
                innerStackView.addArrangedSubview(footnoteLabel)
            }
            
            if let buttonTitle = page.buttonTitle,
               let buttonAction = page.buttonAction {
                let button = HighlightableButton()
                button.setTitle(buttonTitle, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 22)
                button.tintColor = .white
                button.backgroundColor = .systemBlue
                button.layer.cornerRadius = 12
                button.heightAnchor.constraint(equalToConstant: 48).isActive = true
                button.addTarget(self, action: buttonAction, for: .touchUpInside)
                innerStackView.addArrangedSubview(button)
            }
            
            let innerView = UIView()
            innerView.addSubview(innerStackView)
            
            NSLayoutConstraint.activate([
                playerView.widthAnchor.constraint(equalTo: innerStackView.widthAnchor),
                playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: videoUrl.videoAspectRatio ?? 1),
                
                innerStackView.centerXAnchor.constraint(equalTo: innerView.centerXAnchor),
                innerStackView.centerYAnchor.constraint(equalTo: innerView.centerYAnchor),
                innerStackView.leadingAnchor.constraint(equalTo: innerView.leadingAnchor, constant: 20),
                
                innerView.trailingAnchor.constraint(equalTo: innerStackView.trailingAnchor, constant: 20),
            ])
            
            return innerView
        }
        
        outerStackView = UIStackView(arrangedSubviews: pages)
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        outerStackView.distribution = .fillEqually
        
        let outerView = UIView()
        outerView.translatesAutoresizingMaskIntoConstraints = false
        outerView.addSubview(outerStackView)
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.addSubview(outerView)
        view.addSubview(scrollView)
        
        pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.currentPageIndicatorTintColor = .systemGray
        pageControl.pageIndicatorTintColor = .systemGray5
        pageControl.numberOfPages = pages.count - 1
        pageControl.isEnabled = false
        view.addSubview(pageControl)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            safeArea.bottomAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: 24),
            safeArea.trailingAnchor.constraint(equalTo: pageControl.trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            pageControl.topAnchor.constraint(equalTo: outerView.bottomAnchor, constant: 24),
            pageControl.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            
            outerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            outerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            outerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: CGFloat(pages.count - 1)),
            
            outerStackView.topAnchor.constraint(equalTo: outerView.topAnchor),
            outerStackView.bottomAnchor.constraint(equalTo: outerView.bottomAnchor),
            outerStackView.leadingAnchor.constraint(equalTo: outerView.leadingAnchor),
            outerStackView.trailingAnchor.constraint(equalTo: outerView.trailingAnchor),
        ])
        
        updatePages()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePages), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        view.layoutIfNeeded()
        scrollView.contentSize = outerStackView.frame.size
        scrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        if width != 0 {
            var currentPage = Int((scrollView.contentOffset.x / width).rounded())
            if currentPage == 5 && pages[5].isHidden {
                currentPage = 6
            }
            pageControl.currentPage = currentPage
            if previousPage != currentPage {
                if let previousPage = previousPage {
                    players[previousPage].pause()
                }
                let player = players[currentPage]
                player.seek(to: .zero)
                player.rate = 0.1
                previousPage = currentPage
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak player] in
                    if player?.rate != 0 {
                        player?.rate = 1.3
                    }
                }
            }
        }
    }
    
    @objc func jumpToSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
    @objc func endOnboarding() {
        UserDefaults.standard.set(true, forKey: "init")
        dismiss(animated: true, completion: nil)
    }
    
    @objc func updatePages() {
        if Keyboard.isEnabled {
            pages[5].isHidden = true
            pages[6].isHidden = false
        } else {
            pages[6].isHidden = true
            pages[5].isHidden = false
        }
        scrollViewDidScroll(scrollView)
    }
}
