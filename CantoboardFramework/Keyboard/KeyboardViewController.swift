//
//  KeyboardViewController.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/14/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

private class LogFormatter: NSObject, DDLogFormatter {
    let dateFormatter: DateFormatter

    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .behavior10_4
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"

        super.init()
    }
    
    func format(message logMessage: DDLogMessage) -> String? {
        let dateAndTime = dateFormatter.string(from: logMessage.timestamp)
        return "\(dateAndTime) [\(logMessage.fileName):\(logMessage.line)]: \(logMessage.message)"
    }
}

open class KeyboardViewController: UIInputViewController {
    private static let isLoggerInited = initLogger()
    
    private let c = InstanceCounter<KeyboardViewController>()
        
    private static func initLogger() -> Bool {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log

        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        fileLogger.logFormatter = LogFormatter()
        DDLog.add(fileLogger)
        
        DDASLLogCapture.start()
        
        return true
    }
    
    private var inputController: InputController?
    private(set) weak var keyboardView: KeyboardView?
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
        
        RimeApi.stateChangeCallbacks.append({ [weak self] rimeApi, newState in
            guard let self = self else { return true }
            
            DispatchQueue.main.async {
                if newState == .failure /*|| newState == .succeeded*/ {
                    let logs = self.fetchLog()
                    DDLogInfo("Rime Engine deployment failed. Log: \(logs)")
                    self.showLogs(logs)
                } else if let keyboardView = self.keyboardView,
                          newState == .succeeded && !keyboardView.isEnabled {
                    DDLogInfo("Enabling keyboard")
                    self.keyboardView?.isEnabled = true
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
        
        let keyboardSize = LayoutConstants.forMainScreen.keyboardSize
        if heightConstraint == nil {
            let heightConstraint = view.heightAnchor.constraint(equalToConstant: keyboardSize.height)
            heightConstraint.priority = .required
            heightConstraint.isActive = true
            self.heightConstraint = heightConstraint
        }
        
        if widthConstraint == nil {
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: keyboardSize.width)
            widthConstraint.priority = .required
            widthConstraint.isActive = true
            self.widthConstraint = widthConstraint
        }
        
        reloadSettings()
        createKeyboardIfNeeded()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        keyboardView?.needsInputModeSwitchKey = needsInputModeSwitchKey
    }
    
    public override func viewWillLayoutSubviews() {
        // Reset the size constraints to handle screen rotation.
        let nextKeyboardSize = LayoutConstants.forMainScreen.keyboardSize
        widthConstraint?.constant = nextKeyboardSize.width
        heightConstraint?.constant = nextKeyboardSize.height
        
        // DDLogInfo("nextKeyboardSize \(widthConstraint?.constant) \(heightConstraint?.constant) \(view.frame)")
        logView?.frame = CGRect(origin: .zero, size: nextKeyboardSize)
        
        super.viewWillLayoutSubviews()
    }
    
    public func createKeyboardIfNeeded() {
        if keyboardView == nil {
            let keyboardView = KeyboardView()
            keyboardView.delegate = self
            keyboardView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(keyboardView)
            
            // EmojiView inside KeyboardView requires AutoLayout.
            NSLayoutConstraint.activate([
                keyboardView.leftAnchor.constraint(equalTo: view.leftAnchor),
                keyboardView.rightAnchor.constraint(equalTo: view.rightAnchor),
                keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
                keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            
            keyboardView.currentRimeSchemaId = inputController?.reverseLookupSchemaId ?? .jyutping
            
            self.keyboardView = keyboardView
            
            inputController = InputController(keyboardViewController: self)
            keyboardView.candidateOrganizer = inputController?.candidateOrganizer
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
            inputController?.keyPressed(.setCharForm(settings.charForm))
            DDLogInfo("Detected change in char form from \(prevSettings.charForm) to \(settings.charForm).")
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
