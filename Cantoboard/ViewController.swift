//
//  ViewController.swift
//  CantoboardApp
//
//  Created by Alex Man on 3/2/21.
//
import UIKit

import CantoboardFramework

class ViewController: UITableViewController {
    @IBOutlet private var charFormControl: UISegmentedControl!
    @IBOutlet private var enableEnglishControl: UISwitch!
    @IBOutlet private var symbolShapeControl: UISegmentedControl!
    @IBOutlet private var spaceOutputControl: UISegmentedControl!
    @IBOutlet private var toneInputControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateSettings()
        
        charFormControl.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        enableEnglishControl.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        symbolShapeControl.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        spaceOutputControl.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        toneInputControl.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func updateSettings(_ sender: Any) {
        let selectedCharForm: CharForm = charFormControl.selectedSegmentIndex == 0 ? .traditionalHK : .simplified
        
        let selectedSymbolShape: SymbolShape
        switch symbolShapeControl.selectedSegmentIndex {
        case 0: selectedSymbolShape = .half
        case 1: selectedSymbolShape = .smart
        case 2: selectedSymbolShape = .full
        default: selectedSymbolShape = .smart
        }
        
        let spaceOutputMode: SpaceOutputMode = spaceOutputControl.selectedSegmentIndex == 0 ? .input : .bestCandidate
        let toneInputMode: ToneInputMode =  toneInputControl.selectedSegmentIndex == 0 ? .longPress : .vxq
        
        var settings = Settings()
        settings.charForm = selectedCharForm
        settings.isEnablingEnglishInput = enableEnglishControl.isOn
        settings.symbolShape = selectedSymbolShape
        settings.spaceOutputMode = spaceOutputMode
        settings.rimeSettings.toneInputMode = toneInputMode
        Settings.save(settings)
    }
    
    @objc func appMovedToBackground(_ notification: NSNotification) {
        populateSettings()
    }
    
    private func populateSetting(toSegmentedControl: UISegmentedControl, settingToIndexMapper: ((Settings) -> Int)) {
        let selectedIndex = settingToIndexMapper(Settings.cached)
        toSegmentedControl.selectedSegmentIndex = selectedIndex
    }
    
    private func populateSettings() {
        let settings = Settings.reload()
        populateCharFormSetting(settings)
        populateEnableEnglish(settings)
        populateSymbolShape(settings)
        populateSpaceOutputMode(settings)
        populateToneInput(settings)
    }
    
    private func populateCharFormSetting(_ settings: Settings) {
        populateSetting(toSegmentedControl: charFormControl, settingToIndexMapper: {
            switch $0.charForm {
            case .traditionalHK, .traditionalTW: return 0
            case .simplified: return 1
            }
        })
    }
    
    private func populateEnableEnglish(_ settings: Settings) {
        enableEnglishControl.isOn = settings.isEnablingEnglishInput
    }
    
    private func populateSymbolShape(_ settings: Settings) {
        populateSetting(toSegmentedControl: spaceOutputControl, settingToIndexMapper: {
            switch $0.symbolShape {
            case .half: return 0
            case .smart: return 1
            case .full: return 2
            }
        })
    }
    
    private func populateSpaceOutputMode(_ settings: Settings) {
        populateSetting(toSegmentedControl: spaceOutputControl, settingToIndexMapper: {
            switch $0.spaceOutputMode {
            case .input: return 0
            case .bestCandidate: return 1
            }
        })
    }
    
    private func populateToneInput(_ settings: Settings) {
        populateSetting(toSegmentedControl: toneInputControl, settingToIndexMapper: {
            switch $0.rimeSettings.toneInputMode {
            case .longPress: return 0
            case .vxq: return 1
            }
        })
    }
}
