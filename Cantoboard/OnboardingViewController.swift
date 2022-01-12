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
    static let videoAspectRatio: CGFloat = 374 / 298

    var pagesScrollView: UIScrollView!
    var pagesStackView: UIStackView!
    var pageControl: UIPageControl!

    var pages: [UIStackView] = []
    var pageContainers: [UIView] = []
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
        
        let logoImageView = UIImageView(image: UIImage(named: "AppIcon60x60")!.addPadding(2))
        logoImageView.layer.cornerRadius = 8
        logoImageView.clipsToBounds = true
        logoImageView.widthAnchor.constraint(equalTo: logoImageView.heightAnchor).isActive = true
        
        let navStackView = UIStackView(arrangedSubviews: [logoImageView, navTitle])
        navStackView.translatesAutoresizingMaskIntoConstraints = false
        navStackView.spacing = 12
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navStackView)
        
        let skipButtonItem = UIBarButtonItem(title: LocalizedStrings.onboarding_skip, style: .plain, target: self, action: #selector(endOnboarding))
        skipButtonItem.tintColor = .label
        navigationItem.rightBarButtonItem = skipButtonItem
        
        // view.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1)
        view.backgroundColor = .systemBackground
        
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
            let headingVideoPlayer = playerController.view!
            
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
            
            let textStackView = UIStackView(arrangedSubviews: [headingLabel, contentLabel])
            textStackView.axis = .vertical
            textStackView.alignment = .leading
            textStackView.distribution = .fill
            textStackView.spacing = 24
            
            if let footnote = page.footnote {
                let footnoteLabel = UILabel()
                footnoteLabel.text = footnote
                footnoteLabel.font = .preferredFont(forTextStyle: .footnote)
                footnoteLabel.numberOfLines = 0
                textStackView.addArrangedSubview(footnoteLabel)
            }
            
            if let buttonTitle = page.buttonTitle,
               let buttonAction = page.buttonAction {
                let button = HighlightableButton()
                button.setTitle(buttonTitle, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 22)
                button.tintColor = .white
                button.backgroundColor = .systemBlue
                button.layer.cornerRadius = 12
                button.addTarget(self, action: buttonAction, for: .touchUpInside)
                textStackView.addArrangedSubview(button)
                NSLayoutConstraint.activate([
                    button.heightAnchor.constraint(equalToConstant: 48),
                    button.widthAnchor.constraint(equalTo: textStackView.widthAnchor),
                ])
            }
            
            let pageStackView = UIStackView(arrangedSubviews: [headingVideoPlayer, textStackView])
            pageStackView.translatesAutoresizingMaskIntoConstraints = false
            pageStackView.axis = .horizontal
            pageStackView.alignment = .center
            pageStackView.spacing = 36
            pageStackView.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            pageStackView.isLayoutMarginsRelativeArrangement = true
            
            let playerViewAspectConstraint = headingVideoPlayer.widthAnchor.constraint(equalTo: pageStackView.widthAnchor)
            playerViewAspectConstraint.priority = .defaultLow
            NSLayoutConstraint.activate([
                headingVideoPlayer.widthAnchor.constraint(equalTo: headingVideoPlayer.heightAnchor, multiplier: Self.videoAspectRatio),
                playerViewAspectConstraint,
            ])
            
            return pageStackView
        }
        
        pageContainers = pages.map { page in
            let container = UIView()
            container.addSubview(page)
            NSLayoutConstraint.activate([
                page.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                page.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                page.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ])
            return container
        }
        
        pagesStackView = UIStackView(arrangedSubviews: pageContainers)
        pagesStackView.translatesAutoresizingMaskIntoConstraints = false
        pagesStackView.distribution = .fillEqually
        pagesStackView.axis = .horizontal
        pagesStackView.alignment = .fill
        
        pagesScrollView = UIScrollView()
        pagesScrollView.translatesAutoresizingMaskIntoConstraints = false
        pagesScrollView.isPagingEnabled = true
        pagesScrollView.showsHorizontalScrollIndicator = false
        pagesScrollView.showsVerticalScrollIndicator = false
        pagesScrollView.delegate = self
        pagesScrollView.addSubview(pagesStackView)
        
        view.addSubview(pagesScrollView)
        view.layoutMargins = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        
        let numberOfPages = pages.count - 1
        pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.currentPageIndicatorTintColor = .systemGray
        pageControl.pageIndicatorTintColor = .systemGray5
        pageControl.numberOfPages = numberOfPages
        pageControl.isEnabled = false
        view.addSubview(pageControl)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            safeArea.bottomAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: 24),
            safeArea.trailingAnchor.constraint(equalTo: pageControl.trailingAnchor),
            
            pagesScrollView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            pagesScrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            pagesScrollView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            pagesScrollView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            
            pageControl.topAnchor.constraint(equalTo: pagesStackView.bottomAnchor),
            pageControl.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            
            pagesStackView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            pagesStackView.leadingAnchor.constraint(equalTo: pagesScrollView.leadingAnchor),
            pagesStackView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor, multiplier: CGFloat(numberOfPages)),
        ])
        
        setPagesDirection(pageSize: view.bounds.size)
        
        updatePages()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePages), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pagesScrollView.layoutIfNeeded()
        pagesScrollView.contentSize = pagesStackView.frame.size
        
        if let realignToPageOnLayout = realignToPageOnLayout,
           let currentPage = pages[safe: realignToPageOnLayout] {
                pagesScrollView.contentOffset = currentPage.frame.origin
        }
        realignToPageOnLayout = nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        if width > 0 {
            var currentPage = Int((scrollView.contentOffset.x / (width + 20)).rounded())
            if currentPage < 0 { currentPage = 0 }
            if currentPage > pageContainers.count - 1 { currentPage = pageContainers.count - 1 }
            if currentPage == 5 && pageContainers[5].isHidden {
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if player.rate != 0 {
                        player.rate = 1.3
                    }
                }
            }
        }
    }
    
    private var realignToPageOnLayout: Int?
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        setPagesDirection(pageSize: size)
        
        realignToPageOnLayout = pageControl.currentPage
    }
    
    private func setPagesDirection(pageSize: CGSize) {
        pages.forEach { page in
            let isPortrait = pageSize.width < pageSize.height
            page.axis = isPortrait ? .vertical : .horizontal
            page.distribution = isPortrait ? .equalSpacing : .fillEqually
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
            pageContainers[5].isHidden = true
            pageContainers[6].isHidden = false
        } else {
            pageContainers[6].isHidden = true
            pageContainers[5].isHidden = false
        }
        scrollViewDidScroll(pagesScrollView)
    }
}
