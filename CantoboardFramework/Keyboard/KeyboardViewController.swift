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
    
    private weak var widthConstraint, heightConstraint: NSLayoutConstraint?
    
    private(set) weak var keyboardViewPlaceholder: UIView?
    private weak var keyboardViewWidthConstraint, keyboardViewTopConstraint: NSLayoutConstraint?

    private(set) weak var compositionLabelView: CompositionLabel?
    private(set) weak var compositionResetButton: UIButton?
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
        
        let hasLayoutChanged = layoutConstants.ref.idiom != newLayoutConstants.idiom ||
                               layoutConstants.ref.isPortrait != newLayoutConstants.isPortrait
        layoutConstants.ref = newLayoutConstants
        if hasLayoutChanged {
            inputController?.onLayoutChanged()
        }
    }
    
    var hasCompositionView: Bool = false {
        didSet {
            if hasCompositionView {
                if compositionLabelView == nil {
                    let compositionLabelView = CompositionLabel()
                    view.addSubview(compositionLabelView)
                    self.compositionLabelView = compositionLabelView
                }
            } else {
                compositionLabelView?.removeFromSuperview()
                compositionLabelView = nil
            }
        }
    }
    
    var hasCompositionResetButton: Bool = false {
        didSet {
            if hasCompositionResetButton {
                if compositionResetButton == nil {
                    let compositionResetButton = UIButton()
                    compositionResetButton.setImage(ButtonImage.clear, for: .normal)
                    compositionResetButton.setImage(ButtonImage.clearFilled, for: .highlighted)
                    compositionResetButton.imageView?.contentMode = .center
                    compositionResetButton.tintColor = ButtonColor.keyForegroundColor
                    compositionResetButton.addTarget(self, action: #selector(onCompositionResetButtonClicked), for: .touchUpInside)
                    view.addSubview(compositionResetButton)
                    self.compositionResetButton = compositionResetButton
                }
            } else {
                compositionResetButton?.removeFromSuperview()
                compositionResetButton = nil
            }
        }
    }
    
    private var compositionViewHeight: CGFloat {
        return hasCompositionView ? layoutConstants.ref.compositionViewHeight : .zero
    }
    
    private var keyboardHeight: CGFloat {
        layoutConstants.ref.keyboardHeight + compositionViewHeight
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        Settings.hasFullAccess = hasFullAccess
        view.translatesAutoresizingMaskIntoConstraints = false
        
        createInputController()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        createConstraints()
        refreshLayoutConstants()
    }
    
    public func createInputController() {
        if inputController == nil {
            reloadSettings()
            
            createKeyboardViewPlaceholder()
            inputController = InputController(keyboardViewController: self)
            
            textWillChange(nil)
            textDidChange(nil)
        }
    }
    
    private func createKeyboardViewPlaceholder() {
        guard keyboardViewPlaceholder == nil else { return }
        
        let keyboardViewPlaceholder = UIView()
        keyboardViewPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardViewPlaceholder)
        self.keyboardViewPlaceholder = keyboardViewPlaceholder
    }
    
    private func createConstraints() {
        guard let keyboardViewPlaceholder = keyboardViewPlaceholder else { return }
        if self.heightConstraint == nil {
            let heightConstraint = view.heightAnchor.constraint(equalToConstant: keyboardHeight)
            heightConstraint.priority = .required
            heightConstraint.isActive = true
            self.heightConstraint = heightConstraint
        }
    
        if self.widthConstraint == nil {
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: view.window?.bounds.width ?? 0)
            widthConstraint.priority = .defaultHigh
            widthConstraint.isActive = true
            self.widthConstraint = widthConstraint
        }
        
        let keyboardViewWidthConstraint = keyboardViewPlaceholder.widthAnchor.constraint(equalTo: view.widthAnchor)
        keyboardViewWidthConstraint.priority = .required
        self.keyboardViewWidthConstraint = keyboardViewWidthConstraint
        
        // EmojiView inside KeyboardView requires AutoLayout.
        let keyboardViewTopConstraint = keyboardViewPlaceholder.topAnchor.constraint(equalTo: view.topAnchor, constant: compositionViewHeight)
        keyboardViewTopConstraint.priority = .required
        self.keyboardViewTopConstraint = keyboardViewTopConstraint
        
        NSLayoutConstraint.activate([
            keyboardViewWidthConstraint,
            keyboardViewTopConstraint,
            keyboardViewPlaceholder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            keyboardViewPlaceholder.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        inputController?.createConstraints()
    }
    
    public func destroyInputController() {
        keyboardViewPlaceholder?.removeFromSuperview()

        inputController?.keyboardDisappeared()
        inputController = nil
    }
    
    private func setColorSchemeFromKeyboardAppearance() {
        // Set keyboard color scheme from textDocumentProxy.keyboardAppearance.
        var userInterfaceStyle: UIUserInterfaceStyle = .unspecified
        switch self.textDocumentProxy.keyboardAppearance {
        case .light: userInterfaceStyle = .light
        case .dark: userInterfaceStyle = .dark
        default: ()
        }
        // Do not override overrideUserInterfaceStyle of this view.
        // Otherwise self.traitCollectionDidChange will not be called when system color scheme changes.
        // Instead, override each subview.
        view.subviews.forEach { $0.overrideUserInterfaceStyle = userInterfaceStyle }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // keyboardAppearance is only correct at the initial time.
        // If user changes the system light/dark mode afterwards, keyboardAppearance isn't updated.
        view.subviews.forEach { $0.overrideUserInterfaceStyle = .unspecified }
        
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        let isVisible = isViewLoaded && view.window != nil
        if !isVisible {
            DDLogInfo("Under memory pressure. Unloading invisible KeyboardView. \(self)")
            destroyInputController()
        }
    }
    
    public override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        inputController?.textWillChange(textInput)
    }
    
    public override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        setColorSchemeFromKeyboardAppearance()
        inputController?.textDidChange(textInput)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        guard let hostWindow = view.window else { return }
        // Reset the size constraints to handle screen rotation.
        refreshLayoutConstants()
        
        let layoutConstants = self.layoutConstants.ref
        let hostWindowWidth = hostWindow.bounds.width
        layoutConstants.keyboardWidth = hostWindowWidth
        heightConstraint?.constant = keyboardHeight
        widthConstraint?.constant = hostWindowWidth
        keyboardViewTopConstraint?.constant = compositionViewHeight
        
        let compositionLabelHeight = compositionViewHeight - CompositionLabel.insets.top - CompositionLabel.insets.bottom
        let compositionResetButtonWidth = compositionViewHeight
        if let compositionResetButton = compositionResetButton {
            compositionResetButton.frame = CGRect(
                origin: CGPoint(
                    x: hostWindowWidth - compositionResetButtonWidth,
                    y: 0),
                size: CGSize(width: compositionResetButtonWidth, height: compositionResetButtonWidth))
        }
        
        if let compositionLabelView = compositionLabelView {
            let compositionLabelViewWidthByText = compositionLabelView.getRequiredWidth(height: compositionLabelHeight)
            let compositionLabelViewMinWidth = hostWindowWidth - compositionResetButtonWidth - CompositionLabel.insets.left - CompositionLabel.insets.right
            let compositionLabelViewWidth = max(compositionLabelViewWidthByText, compositionLabelViewMinWidth)
            let compositionLabelViewExcessWidth = max(0, compositionLabelViewWidth - compositionLabelViewMinWidth)
            compositionLabelView.frame = CGRect(
                origin: CGPoint(x: CompositionLabel.insets.left - compositionLabelViewExcessWidth, y: CompositionLabel.insets.top),
                size: CGSize(width: compositionLabelViewWidth, height: compositionLabelHeight))
        }
        
        // DDLogInfo("nextKeyboardSize \(widthConstraint?.constant) \(heightConstraint?.constant) \(view.frame)")
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        logView?.frame = keyboardViewPlaceholder?.frame ?? .zero
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
            RimeApi.removeQuickStartFlagFile()
            RimeApi.closeShared()
            DDLogInfo("Detected config change. Redeploying rime. \(RimeApi.shared.version() ?? "")")
        }
        
        if prevSettings.englishLocale != settings.englishLocale {
            EnglishInputEngine.language = settings.englishLocale.rawValue
            DDLogInfo("Detected change in English locale from \(prevSettings.englishLocale) to \(settings.englishLocale).")
        }
        
        if prevSettings.isMixedModeEnabled != settings.isMixedModeEnabled ||
            prevSettings.compositionMode != settings.compositionMode {
            inputController?.refreshInputSettings()
            if prevSettings.isMixedModeEnabled != settings.isMixedModeEnabled {
                DDLogInfo("Detected change in isMixedModeEnabled from \(prevSettings.isMixedModeEnabled) to \(settings.isMixedModeEnabled).")
            }
            if prevSettings.compositionMode != settings.compositionMode {
                DDLogInfo("Detected change in compositionMode from \(prevSettings.compositionMode) to \(settings.compositionMode).")
            }
        }
    }
    
    @objc private func onCompositionResetButtonClicked() {
        inputController?.handleKey(.resetComposition)
    }
}
