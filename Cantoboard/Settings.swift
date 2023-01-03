//
//  Settings.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import UIKit
import CantoboardFramework

struct Section {
    var header: String?
    var options: [Option]
    
    fileprivate init(_ header: String? = nil, _ options: [Option] = []) {
        self.header = header
        self.options = options
    }
}

protocol Option {
    var title: String { get }
    var description: String? { get }
    var videoUrl: String? { get }
    func dequeueCell(with controller: MainViewController) -> UITableViewCell
    func updateSettings()
}

extension Option {
    func makeCell(with view: UIView) -> UITableViewCell {
        let cell = UITableViewCell()
        
        var views: [UIView] = [UILabel(title: title), view]
        if description != nil || videoUrl != nil {
            let button = UIButton()
            button.setImage(CellImage.faq, for: .normal)
            button.isUserInteractionEnabled = false
            views.append(button)
        } else {
            cell.selectionStyle = .none
        }
        
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        
        let contentView = cell.contentView
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
        ])
        
        return cell
    }
}

private class Switch: Option {
    var title: String
    var description: String?
    var videoUrl: String?
    var key: WritableKeyPath<Settings, Bool>
    var value: Bool
    
    private var controller: MainViewController!
    private var control: UISwitch!
    
    init(_ title: String, _ key: WritableKeyPath<Settings, Bool>, _ description: String? = nil, _ videoUrl: String? = nil) {
        self.title = title
        self.key = key
        self.value = Settings.cached[keyPath: key]
        self.description = description
        self.videoUrl = videoUrl
    }
    
    func dequeueCell(with controller: MainViewController) -> UITableViewCell {
        self.controller = controller
        control = UISwitch()
        control.isOn = value
        control.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        return makeCell(with: control)
    }
    
    @objc func updateSettings() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        value = control.isOn
        controller.settings[keyPath: key] = value
        controller.view.endEditing(true)
        Settings.save(controller.settings)
    }
}

private class Segment<T: Equatable>: Option {
    var title: String
    var description: String?
    var videoUrl: String?
    var key: WritableKeyPath<Settings, T>
    var value: T
    var options: KeyValuePairs<String, T>
    
    private var controller: MainViewController!
    private var control: UISegmentedControl!
    
    init(_ title: String, _ key: WritableKeyPath<Settings, T>, _ options: KeyValuePairs<String, T>, _ description: String? = nil, _ videoUrl: String? = nil) {
        self.title = title
        self.key = key
        self.value = Settings.cached[keyPath: key]
        self.options = options
        self.description = description
        self.videoUrl = videoUrl
    }
    
    func dequeueCell(with controller: MainViewController) -> UITableViewCell {
        self.controller = controller
        control = UISegmentedControl(items: options.map { $0.key })
        control.selectedSegmentIndex = options.firstIndex(where: { $1 == value })!
        control.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        return makeCell(with: control)
    }
    
    @objc func updateSettings() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        value = options[control.selectedSegmentIndex].value
        controller.settings[keyPath: key] = value
        controller.view.endEditing(true)
        Settings.save(controller.settings)
    }
}

extension Settings {
    private var enableCorrector: Bool {
        get { rimeSettings.enableCorrector }
        set { rimeSettings.enableCorrector = newValue }
    }
    
    static func buildSections() -> [Section] {
        let padSection = Section(
            LocalizedStrings.padSettings,
            [
                Segment(LocalizedStrings.candidateBarStyle, \.fullPadCandidateBar, [
                        LocalizedStrings.candidateBarStyle_full: true,
                        LocalizedStrings.candidateBarStyle_ios: false,
                ]),
                Segment(LocalizedStrings.padLeftSysKey, \.padLeftSysKeyAsKeyboardType, [
                        LocalizedStrings.padLeftSysKey_default: false,
                        LocalizedStrings.padLeftSysKey_keyboardType: true,
                    ],
                    LocalizedStrings.padLeftSysKey_description
                ),
            ]
        )
        
        return [
            Section(
                LocalizedStrings.inputMethodSettings,
                [
                    Switch(LocalizedStrings.mixedMode, \.isMixedModeEnabled,
                           LocalizedStrings.mixedMode_description, "Guide1-2"),
                    Switch(LocalizedStrings.longPressSymbolKeys, \.isLongPressSymbolKeysEnabled, LocalizedStrings.longPressSymbolKeys_description),
                    Switch(LocalizedStrings.smartFullStop, \.isSmartFullStopEnabled,
                           LocalizedStrings.smartFullStop_description, "Guide8-1"),
                    Switch(LocalizedStrings.audioFeedback, \.isAudioFeedbackEnabled),
                    Switch(LocalizedStrings.tapHapticFeedback, \.isTapHapticFeedbackEnabled),
                    Segment(LocalizedStrings.candidateFontSize, \.candidateFontSize, [
                            LocalizedStrings.candidateFontSize_normal: .normal,
                            LocalizedStrings.candidateFontSize_large: .large,
                    ]),
                    Segment(LocalizedStrings.symbolShape, \.symbolShape, [
                            LocalizedStrings.symbolShape_half: .half,
                            LocalizedStrings.symbolShape_full: .full,
                            LocalizedStrings.symbolShape_smart: .smart,
                        ],
                        LocalizedStrings.symbolShape_description, "Guide9-1"
                    ),
                    Switch(LocalizedStrings.showBottomLeftSwitchLangButton, \.showBottomLeftSwitchLangButton,
                           LocalizedStrings.showBottomLeftSwitchLangButton_description),
                    Switch(LocalizedStrings.enableCharPreview, \.enableCharPreview),
                ]
            ),
            UIDevice.current.userInterfaceIdiom == .pad ? padSection : nil,
            Section(
                LocalizedStrings.mixedInputSettings,
                [
                    Switch(LocalizedStrings.smartSpace, \.isSmartEnglishSpaceEnabled,
                           LocalizedStrings.smartSpace_description),
                    Segment(LocalizedStrings.smartSymbolShapeDefault, \.smartSymbolShapeDefault, [
                            LocalizedStrings.smartSymbolShapeDefault_half: .half,
                            LocalizedStrings.smartSymbolShapeDefault_full: .full,
                        ],
                        LocalizedStrings.smartSymbolShapeDefault_description, "Guide10-3"
                    ),
                ]
            ),
            Section(
                LocalizedStrings.chineseInputSettings,
                [
                    Switch(LocalizedStrings.enablePredictiveText, \.enablePredictiveText,
                           LocalizedStrings.enablePredictiveText_description),
                    Switch(LocalizedStrings.predictiveTextOffensiveWord, \.predictiveTextOffensiveWord,
                           LocalizedStrings.predictiveTextOffensiveWord_description),
                    Segment(LocalizedStrings.compositionMode, \.compositionMode, [
                            LocalizedStrings.compositionMode_immediate: .immediate,
                            LocalizedStrings.compositionMode_multiStage: .multiStage,
                        ],
                        LocalizedStrings.compositionMode_description, "Guide2-1"
                    ),
                    Segment(LocalizedStrings.spaceAction, \.spaceAction, [
                            LocalizedStrings.spaceAction_nextPage: .nextPage,
                            LocalizedStrings.spaceAction_insertCandidate: .insertCandidate,
                            LocalizedStrings.spaceAction_insertText: .insertText,
                    ]),
                    Segment(LocalizedStrings.fullWidthSpace, \.fullWidthSpaceMode, [
                            LocalizedStrings.fullWidthSpace_shift: .shift,
                            LocalizedStrings.fullWidthSpace_off: .off,
                        ], LocalizedStrings.fullWidthSpace_description
                    ),
                    Segment(LocalizedStrings.showRomanizationMode, \.showRomanizationMode, [
                            LocalizedStrings.showRomanizationMode_never: .never,
                            LocalizedStrings.showRomanizationMode_always: .always,
                            LocalizedStrings.showRomanizationMode_onlyInNonCantoneseMode: .onlyInNonCantoneseMode,
                    ]),
                    Switch(LocalizedStrings.enableCorrector, \.enableCorrector,
                           LocalizedStrings.enableCorrector_description, "Guide12-1"),
                    Segment(LocalizedStrings.toneInputMode, \.toneInputMode, [
                            LocalizedStrings.toneInputMode_vxq: .vxq,
                            LocalizedStrings.toneInputMode_longPress: .longPress,
                        ],
                        LocalizedStrings.toneInputMode_description, "Guide3-2"
                    ),
                    Switch(LocalizedStrings.enableHKCorrection, \.enableHKCorrection),
                    Segment(LocalizedStrings.cangjieVersion, \.cangjieVersion, [
                            LocalizedStrings.cangjie3: .cangjie3,
                            LocalizedStrings.cangjie5: .cangjie5,
                        ]
                    ),
                ]
            ),
            Section(
                LocalizedStrings.englishInputSettings,
                [
                    Switch(LocalizedStrings.autoCap, \.isAutoCapEnabled),
                    Switch(LocalizedStrings.shouldShowEnglishExactMatch, \.shouldShowEnglishExactMatch),
                    Segment(LocalizedStrings.englishLocale, \.englishLocale, [
                            LocalizedStrings.englishLocale_au: .au,
                            LocalizedStrings.englishLocale_ca: .ca,
                            LocalizedStrings.englishLocale_gb: .gb,
                            LocalizedStrings.englishLocale_us: .us,
                    ]),
                ]
            ),
        ].compactMap({ $0 })
    }
}
