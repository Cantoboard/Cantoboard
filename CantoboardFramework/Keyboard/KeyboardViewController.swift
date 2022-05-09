//
//  KeyboardViewController.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/14/21.
//

import Foundation
import UIKit
import os
import CocoaLumberjackSwift

open class KeyboardViewController: UIInputViewController {
    private static let isLoggerInited = initLogger()
    private static var count = 0;
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<KeyboardViewController>()
    
    private var inputController: InputController?
    
    private var _state: KeyboardState
    var state: KeyboardState {
        get { _state }
        set { changeState(prevState: _state, newState: newValue) }
    }
    
    private(set) weak var keyboardView: BaseKeyboardView?
    private(set) weak var keyboardViewPlaceholder: UIView?

    private weak var widthConstraint, heightConstraint: NSLayoutConstraint?
    private weak var keyboardViewWidthConstraint, keyboardViewTopConstraint: NSLayoutConstraint?

    private(set) weak var compositionLabelView: CompositionLabel?
    private(set) weak var compositionResetButton: UIButton?
    
    private(set) weak var filterBarView: FilterBarView?
    
    private weak var logView: UITextView?
    
    private(set) var layoutConstants: Reference<LayoutConstants> = Reference(LayoutConstants.forMainScreen)

    private let log = OSLog(subsystem: "org.cantoboard.CantoboardExtension", category: "PointsOfInterest")
    private let signpostID: OSSignpostID
    private let instanceId: Int
    
    private let initStartTime: Date = Date()
    
    public override init(nibName: String?, bundle: Bundle?) {
        instanceId = Self.count
        Self.count += 1

        signpostID = OSSignpostID(log: log)

        os_signpost(.begin, log: log, name: "init", signpostID: signpostID, "%d", instanceId)
        os_signpost(.begin, log: log, name: "total", signpostID: signpostID, "%d", instanceId)
        
        _ = Self.isLoggerInited
        self._state = KeyboardState()
        
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
        
        os_signpost(.end, log: log, name: "init", signpostID: signpostID, "%d", instanceId)
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
        keyboardView?.layoutConstants.ref = newLayoutConstants
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
    
    var hasFilterBar: Bool = false {
        didSet {
            if hasFilterBar {
                if filterBarView == nil {
                    let filterBarView = FilterBarView(keyboardState: state)
                    view.addSubview(filterBarView)
                    filterBarView.delegate = inputController
                    self.filterBarView = filterBarView
                }
            } else {
                filterBarView?.removeFromSuperview()
                filterBarView = nil
            }
        }
    }
    
    private var topViewHeight: CGFloat {
        var height: CGFloat = 0
        if hasFilterBar {
            height += layoutConstants.ref.filterBarViewHeight
        }
        if hasCompositionView {
            height += layoutConstants.ref.compositionViewHeight
        }
        return height
    }
    
    private var keyboardHeight: CGFloat {
        layoutConstants.ref.keyboardHeight + topViewHeight
    }
    
    public override func viewDidLoad() {
        DDLogInfo("KeyboardViewController Profiling \(instanceId) viewDidLoad start time: \(Date().timeIntervalSince(initStartTime) * 1000)")
        
        os_signpost(.begin, log: log, name: "viewDidLoad", signpostID: signpostID, "%d", instanceId)
        
        super.viewDidLoad()
        
        Settings.hasFullAccess = hasFullAccess
        view.translatesAutoresizingMaskIntoConstraints = false
        createKeyboardViewPlaceholder()
        
        view.frame = CGRect(origin: .zero, size: layoutConstants.ref.keyboardSize)
        
        os_signpost(.end, log: log, name: "viewDidLoad", signpostID: signpostID, "%d", instanceId)
        DDLogInfo("KeyboardViewController Profiling \(instanceId) viewDidLoad end time: \(Date().timeIntervalSince(initStartTime) * 1000)")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        DDLogInfo("KeyboardViewController Profiling \(instanceId) viewWillAppear start time: \(Date().timeIntervalSince(initStartTime) * 1000)")
        
        os_signpost(.begin, log: log, name: "viewWillAppear", signpostID: signpostID, "%d", instanceId)
        
        super.viewWillAppear(animated)
        
        createInputController()
        
        refreshLayoutConstants()
        createConstraints()
        
        os_signpost(.end, log: log, name: "viewWillAppear", signpostID: signpostID, "%d", instanceId)
        
        DDLogInfo("KeyboardViewController Profiling \(instanceId) viewWillAppear end time: \(Date().timeIntervalSince(initStartTime) * 1000)")
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        os_signpost(.begin, log: log, name: "viewDidAppear", signpostID: signpostID, "%d", instanceId)
        
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async { [self] in
            DDLogInfo("KeyboardViewController Profiling \(instanceId) prepare start time: \(Date().timeIntervalSince(initStartTime) * 1000)")
            
            inputController?.prepare()
            
            DDLogInfo("KeyboardViewController Profiling \(instanceId) prepare end time: \(Date().timeIntervalSince(initStartTime) * 1000)")
        }
        
        os_signpost(.end, log: log, name: "viewDidAppear", signpostID: signpostID, "%d", instanceId)
        os_signpost(.end, log: log, name: "total", signpostID: signpostID, "%d", instanceId)
        
        DDLogInfo("KeyboardViewController Profiling \(instanceId) total time: \(Date().timeIntervalSince(initStartTime) * 1000)")
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        inputController?.unprepare()
    }
    
    public func createInputController() {
        guard inputController == nil else { return }
        reloadSettings()
        
        inputController = InputController(keyboardViewController: self)
        createKeyboardView()
        filterBarView?.delegate = inputController
        
        textWillChange(nil)
        textDidChange(nil)
    }
    
    private func createKeyboardView() {
        guard let inputController = inputController,
              let keyboardViewPlaceholder = keyboardViewPlaceholder,
              let candidateOrganizer = inputController.candidateOrganizer
            else { return }
        
        let keyboardView: BaseKeyboardView
        
        if state.shouldUseKeypad {
            keyboardView = KeypadView(state: state)
        } else {
            keyboardView = KeyboardView(state: state)
        }
        keyboardView.candidateOrganizer = candidateOrganizer
        keyboardView.delegate = inputController
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardViewPlaceholder.addSubview(keyboardView)
        
        self.keyboardView = keyboardView
        
        createConstraints()
    }
    
    private func createKeyboardViewPlaceholder() {
        guard keyboardViewPlaceholder == nil else { return }
        
        let keyboardViewPlaceholder = UIView()
        keyboardViewPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardViewPlaceholder)
        self.keyboardViewPlaceholder = keyboardViewPlaceholder
    }
    
    private func recreateKeyboardViewIfNeeded() {
        if state.shouldUseKeypad && keyboardView is KeyboardView ||
           !state.shouldUseKeypad && keyboardView is KeypadView {
            keyboardView?.removeFromSuperview()
            createKeyboardView()
        }
    }
    
    private func createConstraints() {
        guard let keyboardViewPlaceholder = keyboardViewPlaceholder,
              let keyboardView = keyboardView
            else { return }
        
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
        
        if self.keyboardViewWidthConstraint == nil {
            let keyboardViewWidthConstraint = keyboardViewPlaceholder.widthAnchor.constraint(equalTo: view.widthAnchor)
            keyboardViewWidthConstraint.priority = .required
            self.keyboardViewWidthConstraint = keyboardViewWidthConstraint
        }
        
        if self.keyboardViewTopConstraint == nil {
            // EmojiView inside KeyboardView requires AutoLayout.
            let keyboardViewTopConstraint = keyboardViewPlaceholder.topAnchor.constraint(equalTo: view.topAnchor, constant: topViewHeight)
            keyboardViewTopConstraint.priority = .required
            self.keyboardViewTopConstraint = keyboardViewTopConstraint
        }
        
        NSLayoutConstraint.activate([
            keyboardViewWidthConstraint!,
            keyboardViewTopConstraint!,
            keyboardViewPlaceholder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            keyboardViewPlaceholder.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        NSLayoutConstraint.activate([
            keyboardView.leftAnchor.constraint(equalTo: keyboardViewPlaceholder.leftAnchor),
            keyboardView.rightAnchor.constraint(equalTo: keyboardViewPlaceholder.rightAnchor),
            keyboardView.topAnchor.constraint(equalTo: keyboardViewPlaceholder.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: keyboardViewPlaceholder.bottomAnchor),
        ])
    }
    
    public func destroyInputController() {
        keyboardView?.removeConstraints(keyboardView?.constraints ?? [])
        keyboardView?.removeFromSuperview()
        keyboardViewPlaceholder?.removeFromSuperview()

        inputController?.keyboardDisappeared()
        inputController = nil
    }
    
    private func changeState(prevState: KeyboardState, newState: KeyboardState) {
        _state = newState
        
        if prevState.shouldUseKeypad != newState.shouldUseKeypad {
            recreateKeyboardViewIfNeeded()
        }
        
        keyboardView?.state = newState
        filterBarView?.keyboardState = newState
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
        keyboardViewTopConstraint?.constant = topViewHeight
        
        var topViewY: CGFloat = 0
        let compositionLabelHeight = layoutConstants.compositionViewHeight - CompositionLabel.insets.top - CompositionLabel.insets.bottom
        let compositionResetButtonWidth = layoutConstants.compositionViewHeight
        if let compositionResetButton = compositionResetButton {
            compositionResetButton.frame = CGRect(
                origin: CGPoint(
                    x: hostWindowWidth - compositionResetButtonWidth,
                    y: topViewY),
                size: CGSize(width: compositionResetButtonWidth, height: compositionResetButtonWidth))
        }
        
        if let compositionLabelView = compositionLabelView {
            let compositionLabelViewWidthByText = compositionLabelView.getRequiredWidth(height: compositionLabelHeight)
            let compositionLabelViewMinWidth = hostWindowWidth - compositionResetButtonWidth - CompositionLabel.insets.left - CompositionLabel.insets.right
            let compositionLabelViewWidth = max(compositionLabelViewWidthByText, compositionLabelViewMinWidth)
            let compositionLabelViewExcessWidth = max(0, compositionLabelViewWidth - compositionLabelViewMinWidth)
            compositionLabelView.frame = CGRect(
                origin: CGPoint(x: CompositionLabel.insets.left - compositionLabelViewExcessWidth, y: topViewY + CompositionLabel.insets.top),
                size: CGSize(width: compositionLabelViewWidth, height: compositionLabelHeight))
            
            topViewY += layoutConstants.compositionViewHeight
        }

        if let filterBarView = filterBarView {
            filterBarView.frame = CGRect(
                origin: CGPoint(x: 0, y: topViewY),
                size: CGSize(width: hostWindowWidth, height: layoutConstants.filterBarViewHeight))
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
