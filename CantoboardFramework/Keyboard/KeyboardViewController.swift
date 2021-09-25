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
    private let c = InstanceCounter<KeyboardViewController>()
    
    private var inputController: InputController?
    private(set) weak var keyboardViewPlaceholder: UIView?
    private weak var keyboardWidthConstraint, superviewCenterXConstraint: NSLayoutConstraint?
    private weak var widthConstraint, heightConstraint: NSLayoutConstraint?
    private weak var logView: UITextView?
    
    private(set) var layoutConstants: Reference<LayoutConstants> = Reference(LayoutConstants.forMainScreen)
    
    public override init(nibName: String?, bundle: Bundle?) {
        _ = Self.isLoggerInited
        
        super.init(nibName: nibName, bundle: bundle)
        
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
    
    // To make sure keyboard layout is updated in the test app. This isn't for the keyboard extension.
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        view.setNeedsLayout()
    }
    
    private func refreshLayoutConstants() {
        guard let windowSize = view.superview?.window?.bounds else { return }
        let isWindowSmall = windowSize.width <= 320
        
        DDLogInfo("refreshLayoutConstants Screen size \(UIScreen.main.bounds.size) superview size \(windowSize)")

        // On iPad, UIScreen.main.bounds isn't reliable if task switcher is used.
        // The only reliable source of screen orientation is the window width.
        let isPortrait = windowSize.size.width <= UIScreen.main.bounds.size.minDimension
        
        let isPadFloatingMode = UIDevice.current.userInterfaceIdiom == .pad && traitCollection.userInterfaceIdiom == .pad && isWindowSmall
        let isPadCompatibleMode = UIDevice.current.userInterfaceIdiom == .pad && traitCollection.userInterfaceIdiom == .phone
        
        DDLogInfo("iPad special mode debug UIDevice userInterfaceIdiom \(UIDevice.current.userInterfaceIdiom.rawValue) traitCollection \(traitCollection)")
        
        let newLayoutConstants: LayoutConstants
        if isPadFloatingMode {
            DDLogInfo("Using isPadFloatingMode")
            newLayoutConstants = LayoutConstants.getContants(screenSize: CGSize(width: 320, height: 254))
        } else if isPadCompatibleMode {
            // iPad's compatiblity mode has a bug. UIScreen doesn't return the right resolution.
            // We cannot rely on the size. We could only infer the screen direction from it.
            let size = isPortrait ? CGSize(width: 375, height: 667) : CGSize(width: 667, height: 375)
            DDLogInfo("Using isPadCompatibleMode \(size)")
            newLayoutConstants = LayoutConstants.getContants(screenSize: size)
        } else {
            let reportedScreenSize = UIScreen.main.bounds.size
            let correctedScreenSize = isPortrait ? reportedScreenSize.asPortrait : reportedScreenSize.asLandscape
            DDLogInfo("refreshLayoutConstants reportedScreenSize \(reportedScreenSize) correctedScreenSize \(correctedScreenSize)")
            DDLogInfo("Using \(correctedScreenSize)")
            newLayoutConstants = LayoutConstants.getContants(screenSize: correctedScreenSize)
        }
        
        let hasLayoutChanged = layoutConstants.ref.idiom != newLayoutConstants.idiom
        layoutConstants.ref = newLayoutConstants
        if hasLayoutChanged {
            inputController?.onIdiomChanged()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        refreshLayoutConstants()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        Settings.hasFullAccess = hasFullAccess
        
        let layoutConstants = self.layoutConstants.ref
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: layoutConstants.keyboardHeight)
        heightConstraint.priority = .required
        heightConstraint.isActive = true
        self.heightConstraint = heightConstraint
    
        let widthConstraint = view.widthAnchor.constraint(equalToConstant: 1) // Just a placeholder. Value will be reset on viewWillLayoutSubviews()
        widthConstraint.priority = .required
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint
    
        let keyboardViewPlaceholder = UIView()
        keyboardViewPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardViewPlaceholder)
        self.keyboardViewPlaceholder = keyboardViewPlaceholder
        
        let keyboardWidthConstraint = keyboardViewPlaceholder.widthAnchor.constraint(equalTo: view.widthAnchor)
        keyboardWidthConstraint.priority = .required
        keyboardWidthConstraint.isActive = true
        self.keyboardWidthConstraint = keyboardWidthConstraint
        
        // EmojiView inside KeyboardView requires AutoLayout.
        NSLayoutConstraint.activate([
            keyboardViewPlaceholder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            keyboardViewPlaceholder.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardViewPlaceholder.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        reloadSettings()
        createKeyboardIfNeeded()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshLayoutConstants()
        
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
    
    public override func viewWillLayoutSubviews() {
        guard let hostWindow = view.superview?.window else { return }
        // Reset the size constraints to handle screen rotation.
        refreshLayoutConstants()
        
        let layoutConstants = self.layoutConstants.ref
        let hostWindowWidth = hostWindow.bounds.width
        layoutConstants.keyboardWidth = hostWindowWidth
        heightConstraint?.constant = layoutConstants.keyboardHeight
        widthConstraint?.constant = hostWindowWidth
        
        super.viewWillLayoutSubviews()
        
        // DDLogInfo("nextKeyboardSize \(widthConstraint?.constant) \(heightConstraint?.constant) \(view.frame)")
        logView?.frame = CGRect(origin: .zero, size: layoutConstants.keyboardSize)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inputController?.keyboardDisappeared()
    }
    
    public func createKeyboardIfNeeded() {
        if inputController == nil {
            inputController = InputController(keyboardViewController: self)
            
            textWillChange(nil)
            textDidChange(nil)
        }
    }
    
    public func destroyKeyboard() {
        inputController = nil
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
        
        if prevSettings.isMixedModeEnabled != settings.isMixedModeEnabled {
            inputController?.enforceInputMode()
            DDLogInfo("Detected change in isMixedModeEnabled from \(prevSettings.isMixedModeEnabled) to \(settings.isMixedModeEnabled).")
        }
    }
}
