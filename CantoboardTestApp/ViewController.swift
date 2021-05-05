//
//  ViewController.swift
//  StockboardApp
//
//  Created by Alex Man on 1/14/21.
//

import UIKit

import CantoboardFramework

class ViewController: UIViewController, UITextViewDelegate {
    var textbox: UITextView!
    var keyboardController: KeyboardViewController?
    var createKeyboard: Bool = false
    
    // For debugging mem leak.
    func recreateKeyboard() {
        if let keyboard = keyboardController {
            if self.createKeyboard {
                keyboard.createKeyboardIfNeeded()
            } else {
                keyboard.destroyKeyboard()
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
        
        view.backgroundColor = .systemGray5
        view.addSubview(keyboard.view)
        addChild(keyboard)
        
        NSLayoutConstraint.activate([
            keyboard.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            keyboard.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            keyboard.view.bottomAnchor.constraint(equalTo: textbox.topAnchor),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        // Uncomment to generate English Dictionaries.
        DefaultDictionary.createDb(locale: "en_US")
        DefaultDictionary.createDb(locale: "en_CA")
        DefaultDictionary.createDb(locale: "en_GB")
        DefaultDictionary.createDb(locale: "en_AU")
        NSLog("EnglishDictionary Created.")
         */
        
        textbox = UITextView()
        textbox.translatesAutoresizingMaskIntoConstraints = false
        textbox.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(textbox)
        textbox.becomeFirstResponder()
        textbox.delegate = self
        
        NSLayoutConstraint.activate([
            textbox.leftAnchor.constraint(equalTo: view.leftAnchor),
            textbox.rightAnchor.constraint(equalTo: view.rightAnchor),
            textbox.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        createKeyboardController()
        
        // englishDictionary
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
