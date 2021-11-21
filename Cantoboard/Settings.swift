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
    func dequeueCell(with settings: Reference<Settings>) -> UITableViewCell
    func updateSettings()
}

extension Option {
    func makeCell(with view: UIView) -> UITableViewCell {
        let cell = UITableViewCell()
        
        var views: [UIView] = [UILabel(title: title), view]
        if videoUrl != nil {
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
    
    private var settings: Reference<Settings>!
    private var control: UISwitch!
    
    init(_ title: String, _ key: WritableKeyPath<Settings, Bool>, _ description: String? = nil, _ videoUrl: String? = nil) {
        self.title = title
        self.key = key
        self.value = Settings.cached[keyPath: key]
        self.description = description
        self.videoUrl = videoUrl
    }
    
    func dequeueCell(with settings: Reference<Settings>) -> UITableViewCell {
        self.settings = settings
        control = UISwitch()
        control.isOn = value
        control.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        return makeCell(with: control)
    }
    
    @objc func updateSettings() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        settings.ref[keyPath: key] = control.isOn
        Settings.save(settings.ref)
    }
}

private class Segment<T: Equatable>: Option {
    var title: String
    var description: String?
    var videoUrl: String?
    var key: WritableKeyPath<Settings, T>
    var value: T
    var options: KeyValuePairs<String, T>
    
    private var settings: Reference<Settings>!
    private var control: UISegmentedControl!
    
    init(_ title: String, _ key: WritableKeyPath<Settings, T>, _ options: KeyValuePairs<String, T>, _ description: String? = nil, _ videoUrl: String? = nil) {
        self.title = title
        self.key = key
        self.value = Settings.cached[keyPath: key]
        self.options = options
        self.description = description
        self.videoUrl = videoUrl
    }
    
    func dequeueCell(with settings: Reference<Settings>) -> UITableViewCell {
        self.settings = settings
        control = UISegmentedControl(items: options.map { $0.key })
        control.selectedSegmentIndex = options.firstIndex(where: { $1 == value })!
        control.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        return makeCell(with: control)
    }
    
    @objc func updateSettings() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        settings.ref[keyPath: key] = options[control.selectedSegmentIndex].value
        Settings.save(settings.ref)
    }
}

class Reference<Type> {
    var ref: Type
    
    init(_ object: Type) {
        ref = object
    }
}

extension Settings {
    public var enableCorrector: Bool {
        get { rimeSettings.enableCorrector }
        set { rimeSettings.enableCorrector = newValue }
    }
    
    static func buildSections() -> [Section] {
        [
            Section(
                LocalizedStrings.inputMethodSettings,
                [
                    Switch(LocalizedStrings.mixedMode, \.isMixedModeEnabled,
                           LocalizedStrings.mixedMode_description, "Guide1-2"),
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
                    LocalizedStrings.symbolShape_description, "Guide9-1"),
                ]
            ),
            Section(
                LocalizedStrings.chineseInputSettings,
                [
                    Segment(LocalizedStrings.compositionMode, \.compositionMode, [
                        LocalizedStrings.compositionMode_immediate: .immediate,
                        LocalizedStrings.compositionMode_multiStage: .multiStage,
                    ],
                    LocalizedStrings.compositionMode_description, "Guide2-1"),
                    Segment(LocalizedStrings.spaceAction, \.spaceAction, [
                        LocalizedStrings.spaceAction_nextPage: .nextPage,
                        LocalizedStrings.spaceAction_insertCandidate: .insertCandidate,
                        LocalizedStrings.spaceAction_insertText: .insertText,
                    ]),
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
                    LocalizedStrings.toneInputMode_description, "Guide3-2"),
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
                        LocalizedStrings.englishLocale_us: .us
                    ]),
                ]
            ),
        ]
    }
}
