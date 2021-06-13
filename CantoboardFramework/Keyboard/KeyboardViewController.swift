//
//  KeyboardViewController.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/14/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

open class KeyboardViewController: UIInputViewController {
    private static let isLoggerInited = initLogger()
    
    // Uncomment this to debug memory leak.
    // private let c = InstanceCounter<KeyboardViewController>()
    
    private var inputController: InputController?
    private(set) weak var keyboardView: KeyboardView?
    private weak var keyboardWidthConstraint, superviewCenterXConstraint: NSLayoutConstraint?
    private weak var widthConstraint, heightConstraint: NSLayoutConstraint?
    private weak var logView: UITextView?
    
    // Touch event near the screen edge are delayed.
    // Overriding preferredScreenEdgesDeferringSystemGestures doesnt work in UIInputViewController,
    // As a workaround we use UILongPressGestureRecognizer to detect taps without delays.
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    private var candidateOrganizer: CandidateOrganizer? {
        get {
            return keyboardView?.candidateOrganizer
        }
        set {
            keyboardView?.candidateOrganizer = newValue
        }
    }
    
    public override init(nibName: String?, bundle: Bundle?) {
        _ = Self.isLoggerInited
        super.init(nibName: nibName, bundle: bundle)
        inputController = InputController(keyboardViewController: self)
        
        RimeApi.stateChangeCallbacks.append({ [weak self] rimeApi, newState in
            guard let self = self else { return true }
            
            DispatchQueue.main.async {
                if newState == .failure {
                    let logs = self.fetchLog()
                    DDLogInfo("Rime Engine deployment failed. Log: \(logs)")
                    self.showLogs(logs)
                } else if newState == .succeeded {
                    DDLogInfo("Enabling keyboard")
                    self.inputController?.reenableKeyboard()
                }
            }
            return false
        })
    }
    
    private func fetchLog() -> [String] {
        let appContainerPath = NSHomeDirectory()
        let errorLogPath = appContainerPath + "/tmp/rime.iOS.ERROR"
        let warnLogPath = appContainerPath + "/tmp/rime.iOS.WARNING"
        let infoLogPath = appContainerPath + "/tmp/rime.iOS.INFO"
        
        let errorLog = try? String(contentsOfFile: errorLogPath)
        let warnLog = try? String(contentsOfFile: warnLogPath)
        let infoLog = try? String(contentsOfFile: infoLogPath)
        
        DDLogInfo("=== Rime logs ===")
        DDLogInfo("Error log: \(errorLog ?? "")")
        DDLogInfo("Warn log: \(warnLog ?? "")")
        DDLogInfo("Info log: \(infoLog ?? "")")
        
        let log = ["=== Rime logs ===\n", "Error log:\n", errorLog ?? "", "Warn log:\n", warnLog ?? "", "Info log:\n", infoLog ?? ""]
        UIPasteboard.general.string = log.joined()
        return log
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        LayoutConstants.currentTraitCollection = traitCollection
        
        Settings.hasFullAccess = hasFullAccess
        
        let layoutConstants = LayoutConstants.forMainScreen
        if heightConstraint == nil {
            let heightConstraint = view.heightAnchor.constraint(equalToConstant: layoutConstants.keyboardSize.height)
            heightConstraint.priority = .required
            heightConstraint.isActive = true
            self.heightConstraint = heightConstraint
        }
        
        if widthConstraint == nil {
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: layoutConstants.superviewSize.width)
            widthConstraint.priority = .required
            widthConstraint.isActive = true
            self.widthConstraint = widthConstraint
        }
        
        reloadSettings()
        createKeyboardIfNeeded()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LayoutConstants.currentTraitCollection = traitCollection
        
        if superviewCenterXConstraint == nil, let superview = view.superview {
            let superviewCenterXConstraint = view.centerXAnchor.constraint(equalTo: superview.centerXAnchor)
            self.superviewCenterXConstraint = superviewCenterXConstraint
            superviewCenterXConstraint.isActive = true
        }
        
        reloadSettings()
        createKeyboardIfNeeded()
    }
    
    public override func didReceiveMemoryWarning() {
        let isVisible = isViewLoaded && view.window != nil
        if !isVisible {
            DDLogInfo("Under memory pressure. Unloading invisible KeyboardView. \(self)")
            destroyKeyboard()
        }
    }
    
    public override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        inputController?.textWillChange(textInput)
    }
    
    public override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        inputController?.textDidChange(textInput)
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        LayoutConstants.currentTraitCollection = traitCollection
        view.setNeedsLayout()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        LayoutConstants.currentTraitCollection = traitCollection
    }
    
    public override func viewWillLayoutSubviews() {
        // Reset the size constraints to handle screen rotation.
        let layoutConstants = LayoutConstants.forMainScreen
        keyboardWidthConstraint?.constant = layoutConstants.keyboardSize.width
        heightConstraint?.constant = layoutConstants.keyboardSize.height
        widthConstraint?.constant = layoutConstants.superviewSize.width
        
        super.viewWillLayoutSubviews()
        
        // DDLogInfo("nextKeyboardSize \(widthConstraint?.constant) \(heightConstraint?.constant) \(view.frame)")
        logView?.frame = CGRect(origin: .zero, size: layoutConstants.keyboardSize)
    }
    
    public func createKeyboardIfNeeded() {
        if keyboardView == nil {
            let keyboardView = KeyboardView(state: inputController!.state)
            keyboardView.delegate = self
            keyboardView.translatesAutoresizingMaskIntoConstraints = false
            keyboardView.candidateOrganizer = inputController!.candidateOrganizer
            view.addSubview(keyboardView)
            
            // EmojiView inside KeyboardView requires AutoLayout.
            NSLayoutConstraint.activate([
                keyboardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
                keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            
            let widthConstraint = keyboardView.widthAnchor.constraint(equalToConstant: LayoutConstants.forMainScreen.keyboardSize.width)
            widthConstraint.priority = .required
            widthConstraint.isActive = true
            self.keyboardWidthConstraint = widthConstraint
            
            self.keyboardView = keyboardView
            
            textWillChange(nil)
            textDidChange(nil)
            
            longPressGestureRecognizer = UILongPressGestureRecognizer()
            longPressGestureRecognizer.minimumPressDuration = 0
            longPressGestureRecognizer.delegate = self
            view.addGestureRecognizer(longPressGestureRecognizer)
        }
    }
    
    public func destroyKeyboard() {
        inputController = nil
        
        keyboardView?.removeFromSuperview()
        keyboardView = nil
        
        view.subviews.forEach({ $0.removeFromSuperview() })
        view.gestureRecognizers?.forEach({ view.removeGestureRecognizer($0) })
    }
    
    private func showLogs(_ logs: [String]) {
        let logView = UITextView()
        logView.frame = view.bounds
        logView.isEditable = false
        logView.text = logs.joined()
        
        view.addSubview(logView)
        self.logView = logView
    }
    
    private func reloadSettings() {
        let prevSettings = Settings.cached
        let settings = Settings.reload()
        
        DDLogInfo("Reloaded Settings. prevSettings: \(prevSettings) newSettings: \(settings)")
        
        if prevSettings.rimeSettings != settings.rimeSettings {
            RimeApi.generateSchemaPatchFromSettings()
            RimeApi.closeShared()
            DDLogInfo("Detected config change. Redeploying rime. \(RimeApi.shared.getVersion() ?? "")")
        }
        
        if prevSettings.englishLocale != settings.englishLocale {
            EnglishInputEngine.language = settings.englishLocale.rawValue
            DDLogInfo("Detected change in English locale from \(prevSettings.englishLocale) to \(settings.englishLocale).")
        }
        
        if prevSettings.charForm != settings.charForm {
            SessionState.main.lastCharForm = settings.charForm
            inputController?.keyPressed(.setCharForm(settings.charForm))
            DDLogInfo("Detected change in char form from \(prevSettings.charForm) to \(settings.charForm).")
        }
        
        if prevSettings.isMixedModeEnabled != settings.isMixedModeEnabled {
            inputController?.enforceInputMode()
            DDLogInfo("Detected change in isMixedModeEnabled from \(prevSettings.isMixedModeEnabled) to \(settings.isMixedModeEnabled).")
        }
    }
}

extension KeyboardViewController: KeyboardViewDelegate {
    func handleKey(_ action: KeyboardAction) {
        inputController?.keyPressed(action)
    }
}

extension KeyboardViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        let beganTouches = event.allTouches?.filter { $0.phase == .began }
        if let beganTouches = beganTouches, beganTouches.count > 0 {
            keyboardView?.touchesBeganFromGestureRecoginzer(Set(beganTouches), with: event)
        }
        return false
    }
}
