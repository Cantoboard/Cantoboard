//
//  ViewController.swift
//  StockboardApp
//
//  Created by Alex Man on 1/14/21.
//

import UIKit

import CantoboardFramework

class TestAppViewController: UIViewController, UITextViewDelegate {
    var textbox: UITextView!
    var keyboardController: KeyboardViewController?
    var createKeyboard: Bool = false
    
    // For debugging mem leak.
    func recreateKeyboard() {
        if let keyboard = keyboardController {
            if self.createKeyboard {
                keyboard.createInputController()
            } else {
                keyboard.destroyInputController()
            }
            self.createKeyboard = !self.createKeyboard
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1 / 30) {
            self.recreateKeyboard()
        }
    }
    
    // For debugging mem leak.
    func recreateKeyboardController() {
        if let keyboardController = keyboardController {
            keyboardController.view.removeFromSuperview()
            keyboardController.removeFromParent()
            self.keyboardController = nil
        } else {
            createKeyboardController()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1 / 30) {
            self.recreateKeyboardController()
        }
    }
    
    func createKeyboardController() {
        let keyboard = KeyboardViewController()
        self.keyboardController = keyboard
        keyboard.view.translatesAutoresizingMaskIntoConstraints = false
        
        view.backgroundColor = UIColor(named: "keyboardBackgroundColor")
        view.addSubview(keyboard.view)
        addChild(keyboard)
        
        NSLayoutConstraint.activate([
            keyboard.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            keyboard.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            keyboard.view.bottomAnchor.constraint(equalTo: textbox.topAnchor),
        ])
    }
    
    private var textboxBottomAnchor: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        // Uncomment to generate English Dictionaries.
        DefaultDictionary.createDb(locale: "en_US")
        DefaultDictionary.createDb(locale: "en_CA")
        DefaultDictionary.createDb(locale: "en_GB")
        DefaultDictionary.createDb(locale: "en_AU")
        DDLogInfo("EnglishDictionary Created.")
         */
        
        /*
        let unihanCsvPath = "\(Bundle.main.resourcePath!)/UnihanSource/Unihan12.csv"
        let path = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).path
        LevelDbTable.createUnihanDictionary(unihanCsvPath, dictDbPath: "\(path)/Unihan")
         */
        
        textbox = UITextView()
        textbox.translatesAutoresizingMaskIntoConstraints = false
        textbox.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(textbox)
        textbox.becomeFirstResponder()
        textbox.delegate = self
        textbox.text = """
The Microsoft Open Source Blog takes a look at implementing eBPF support in Windows. "Although support for eBPF was first implemented in the Linux kernel, there has been increasing interest in allowing eBPF to be used on other operating systems and also to extend user-mode services and daemons in addition to just the kernel. Today we are excited to announce a new Microsoft open source project to make eBPF work on Windows 10 and Windows Server 2016 and later. The ebpf-for-windows project aims to allow developers to use familiar eBPF toolchains and application programming interfaces (APIs) on top of existing versions of Windows. Building on the work of others, this project takes several existing eBPF open source projects and adds the “glue” to make them run on Windows."

Python in the browser has long been an item on the wish list of many in the Python community. At this point, though, JavaScript has well-cemented its role as the language embedded into the web and its browsers. The Pyodide project provides a way to run Python in the browser by compiling the existing CPython interpreter to WebAssembly and running that binary within the browser's JavaScript environment. Pyodide came about as part of Mozilla's Iodide project, which has fallen by the wayside, but Pyodide is now being spun out as a community-driven project.
"""
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NSLayoutConstraint.activate([
            textbox.leftAnchor.constraint(equalTo: view.leftAnchor),
            textbox.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        
        textboxBottomAnchor = textbox.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        textboxBottomAnchor.isActive = true
        
        createKeyboardController()
        
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.recreateKeyboardController()
        }
         */
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.recreateKeyboard()
        }
         */
    }
    
    @objc
    func keyboardWillAppear(notification: NSNotification?) {
        guard let keyboardFrame = notification?.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardHeight: CGFloat
        if #available(iOS 11.0, *) {
            keyboardHeight = keyboardFrame.cgRectValue.height - self.view.safeAreaInsets.bottom
        } else {
            keyboardHeight = keyboardFrame.cgRectValue.height
        }

        textboxBottomAnchor.constant = -keyboardHeight
    }

    @objc
    func keyboardWillDisappear(notification: NSNotification?) {
        textboxBottomAnchor.constant = 0.0
    }
    /*
    func textViewDidChange(_ textView: UITextView) {
        guard let markedTextRange = textView.markedTextRange else { return }
        let text = textView.text(in: markedTextRange)
        let sel = textView.selectedRange
        print("textViewDidChange", text, sel)
        // text?.utf8.forEach { print("utf8", String($0, radix: 16, uppercase: false)) }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: DispatchTimeInterval.milliseconds(1000)), execute: {
            print("Lose First Responder")
            textView.resignFirstResponder()
        })
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        guard let markedTextRange = textView.markedTextRange else { return }
        print("textViewDidEndEditing", textView.text(in: markedTextRange))
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {        guard let markedTextRange = textView.markedTextRange else { return }
        let text = textView.text(in: markedTextRange)
        let sel = textView.selectedRange
        print("textViewDidChangeSelection", text, sel)
    }*/
}
