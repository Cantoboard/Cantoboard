//
//  ViewController.swift
//  CantoboardApp
//
//  Created by Alex Man on 3/2/21.
//
import UIKit

import CantoboardFramework

class ViewController: UITableViewController {
    @IBOutlet private var chineseScriptControl: UISegmentedControl!
    @IBOutlet private var enableEnglishControl: UISwitch!
    @IBOutlet private var symbolShapeControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateSettings()
        
        chineseScriptControl.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        enableEnglishControl.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        symbolShapeControl.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func updateSettings(_ sender: Any) {
        let selectedChineseScript: ChineseScript = chineseScriptControl.selectedSegmentIndex == 0 ? .traditionalHK : .simplified
        
        let selectedSymbolShape: SymbolShape
        switch symbolShapeControl.selectedSegmentIndex {
        case 0: selectedSymbolShape = .half
        case 1: selectedSymbolShape = .smart
        case 2: selectedSymbolShape = .full
        default: selectedSymbolShape = .smart
        }
        
        Settings.shared.chineseScript = selectedChineseScript
        Settings.shared.isEnablingEnglishInput = enableEnglishControl.isOn
        Settings.shared.symbolShape = selectedSymbolShape
    }
    
    @objc func appMovedToBackground(_ notification: NSNotification) {
        populateSettings()
    }
    
    private func populateSettings() {
        populateChineseScriptSetting()
        populateEnableEnglish()
        populateSymbolShape()
    }
    
    private func populateChineseScriptSetting() {
        let selectedChineseScript = Settings.shared.chineseScript
        
        let selectedChineseScriptSegmentIndex: Int
        switch selectedChineseScript {
        case .traditionalHK, .traditionalTW: selectedChineseScriptSegmentIndex = 0
        case .simplified: selectedChineseScriptSegmentIndex = 1
        }
        
        chineseScriptControl.selectedSegmentIndex = selectedChineseScriptSegmentIndex
    }
    
    private func populateEnableEnglish() {
        enableEnglishControl.isOn = Settings.shared.isEnablingEnglishInput
    }
    
    private func populateSymbolShape() {
        let symbolShape = Settings.shared.symbolShape
        
        let symbolShapeSegmentIndex: Int
        switch symbolShape {
        case .half: symbolShapeSegmentIndex = 0
        case .full: symbolShapeSegmentIndex = 2
        case .smart: symbolShapeSegmentIndex = 1
        }
        
        symbolShapeControl.selectedSegmentIndex = symbolShapeSegmentIndex
    }
}
