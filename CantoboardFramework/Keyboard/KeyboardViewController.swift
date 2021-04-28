//
//  KeyboardViewController.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/14/21.
//

import Foundation
import UIKit

open class KeyboardViewController: UIInputViewController {
    private var inputController: InputController!
    private(set) weak var keyboardView: KeyboardView?
    private weak var widthConstraint, heightConstraint: NSLayoutConstraint?
    private var logView: UITextView?
    
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
        super.init(nibName: nibName, bundle: bundle)
        
        RimeApi.stateChangeCallbacks.append({ [weak self] rimeApi, newState in
            guard let self = self else { return true }
            
            DispatchQueue.main.async {
                if newState == .failure /*|| newState == .succeeded*/ {
                    let logs = self.fetchLog()
                    NSLog("Rime Engine deployment failed. Log: \(logs)")
                    self.showLogs(logs)
                } else if let keyboardView = self.keyboardView,
                          newState == .succeeded && !keyboardView.isEnabled {
                    NSLog("Enabling keyboard")
                    self.keyboardView?.isEnabled = true
                }
            }
            FileUnlocker.unlockAllOpenedFiles()
            return false
        })
        
        inputController = InputController(keyboardViewController: self)
        // unlockAllOpenedFiles()
    }
    
    /*
    private func unlockAllOpenedFiles() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            FileUnlocker.unlockAllOpenedFiles()
            // Run unlockAllOpenedFiles every minute to avoid iOS killing us for 0xdead10cc.
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60, execute: self.unlockAllOpenedFiles)
        }
    }
    */
    
    private func fetchLog() -> [String] {
        let appContainerPath = NSHomeDirectory()
        let errorLogPath = appContainerPath + "/tmp/rime.iOS.ERROR"
        let warnLogPath = appContainerPath + "/tmp/rime.iOS.WARNING"
        let infoLogPath = appContainerPath + "/tmp/rime.iOS.INFO"
        
        let errorLog = try? String(contentsOfFile: errorLogPath)
        let warnLog = try? String(contentsOfFile: warnLogPath)
        let infoLog = try? String(contentsOfFile: infoLogPath)
        
        NSLog("=== Rime logs ===")
        NSLog("Error log:\n%@", errorLog ?? "")
        NSLog("Warn log:\n%@", warnLog ?? "")
        NSLog("Info log:\n%@", infoLog ?? "")
        
        let log = ["=== Rime logs ===\n", "Error log:\n", errorLog ?? "", "Warn log:\n", warnLog ?? "", "Info log:\n", infoLog ?? ""]
        UIPasteboard.general.string = log.joined()
        return log
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadSettings()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(onNSExtensionHostDidBecomeActive), name: NSNotification.Name.NSExtensionHostDidBecomeActive, object: nil)
        
        heightConstraint = view.heightAnchor.constraint(equalToConstant: LayoutConstants.forMainScreen.keyboardSize.height)
        heightConstraint?.priority = .defaultHigh
        heightConstraint?.isActive = true
        // NSLog("viewDidLoad screen size \(UIScreen.main.bounds.size)")

        createKeyboard()
        
        longPressGestureRecognizer = UILongPressGestureRecognizer()
        longPressGestureRecognizer.minimumPressDuration = 0
        longPressGestureRecognizer.delegate = self
        view.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    public override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        inputController.textWillChange(textInput)
    }
    
    public override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        inputController.textDidChange(textInput)
        keyboardView?.needsInputModeSwitchKey = needsInputModeSwitchKey
    }
    
    public override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        let oldSize = UIScreen.main.bounds.size
        let shortEdge = min(oldSize.width, oldSize.height)
        let longEdge = max(oldSize.width, oldSize.height)
        let newSize = toInterfaceOrientation.isPortrait ? CGSize(width: shortEdge, height: longEdge) : CGSize(width: longEdge, height: shortEdge)
        let nextKeyboardSize = LayoutConstants.getContants(screenSize: newSize).keyboardSize
        
        // NSLog("willRotate New screen size \(newSize)")
        
        widthConstraint?.constant = nextKeyboardSize.width
        heightConstraint?.constant = nextKeyboardSize.height
        
        super.willRotate(to: toInterfaceOrientation, duration: duration)
    }
    
    public override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        let nextKeyboardSize = LayoutConstants.forMainScreen.keyboardSize
        // NSLog("didRotate New screen size \(UIScreen.main.bounds)")
        
        widthConstraint?.constant = nextKeyboardSize.width
        heightConstraint?.constant = nextKeyboardSize.height
        
        super.didRotate(from: fromInterfaceOrientation)
    }
    
    public override func viewWillLayoutSubviews() {
        // On rare occasions, viewDidLoad could pick up the wrong screen size and willRotate/didRotate are not fired.
        // Reset the size constraints here.
        let nextKeyboardSize = LayoutConstants.forMainScreen.keyboardSize
        widthConstraint?.constant = nextKeyboardSize.width
        heightConstraint?.constant = nextKeyboardSize.height
        
        super.viewWillLayoutSubviews()
    }
    
    public func createKeyboard() {
        if keyboardView == nil {
            let keyboardView = KeyboardView()
            keyboardView.delegate = self
            keyboardView.candidateOrganizer = inputController.candidateOrganizer
            keyboardView.translatesAutoresizingMaskIntoConstraints = false
            view.autoresizingMask = []
            view.addSubview(keyboardView)
            
            NSLayoutConstraint.activate([
                keyboardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
                keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            
            let keyboardSize = LayoutConstants.forMainScreen.keyboardSize
            widthConstraint = keyboardView.widthAnchor.constraint(equalToConstant: keyboardSize.width)
            widthConstraint?.isActive = true
            
            keyboardView.currentRimeSchemaId = inputController.reverseLookupSchemaId ?? .jyutping
            
            self.keyboardView = keyboardView
        }
    }
    
    public func destroyKeyboard() {
        keyboardView?.removeFromSuperview()
        keyboardView = nil
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.global(qos: .background).async {
            FileUnlocker.unlockAllOpenedFiles()
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        inputController.clearState()
        super.viewDidDisappear(animated)
        DispatchQueue.global(qos: .background).async {
            FileUnlocker.unlockAllOpenedFiles()
        }
    }
    
    private func showLogs(_ logs: [String]) {
        let logView = UITextView()
        logView.frame = view.bounds
        logView.isEditable = false
        logView.text = logs.joined()
        
        self.logView = logView
        view.addSubview(logView)
    }
    
    public override func viewDidLayoutSubviews() {
        logView?.frame = view.bounds
    }
    
    private func reloadSettings() {
        let prevSettings = Settings.cached
        let settings = Settings.reload()
        
        if prevSettings.rimeSettings != settings.rimeSettings {
            RimeApi.generateSchemaPatchFromSettings()
            RimeApi.closeShared()
            NSLog("Detected config change. Redeploying rime. \(RimeApi.shared.getVersion() ?? "")")
        }
        
        if prevSettings.englishLocale != settings.englishLocale {
            EnglishInputEngine.language = settings.englishLocale.rawValue
            NSLog("Detected change in English locale from \(prevSettings.englishLocale) to \(settings.englishLocale).")
        }
        
        if prevSettings.charForm != settings.charForm {
            inputController.keyPressed(.setCharForm(settings.charForm))
            NSLog("Detected change in char form from \(prevSettings.charForm) to \(settings.charForm).")
        }
    }
    
    @objc private func onNSExtensionHostDidBecomeActive(_ notification: NSNotification) {
        NSLog("Reloading settings onNSExtensionHostDidBecomeActive.")
        reloadSettings()
    }
}

extension KeyboardViewController: KeyboardViewDelegate {
    func handleKey(_ action: KeyboardAction) {
        inputController.keyPressed(action)
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
