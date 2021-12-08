//
//  MainViewController.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import UIKit
import CantoboardFramework

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate {
    var tableView: UITableView!
    var settings: Settings {
        get { Settings.cached }
        set {
            Settings.save(newValue)
            
            if let inputCell = self.tableView.cellForRow(at: [1, 0]) as? InputTableViewCell {
                inputCell.hideKeyboard()
            }
        }
    }
    var sections: [Section] = Settings.buildSections()
    var aboutCells: [(title: String, image: UIImage, action: () -> ())]!
    
    var lastSection: Int { Keyboard.isEnabled ? sections.count + 2 : 1 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Cantoboard"
        tableView = UITableView(frame: view.frame, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        aboutCells = [
            (LocalizedStrings.other_onboarding, CellImage.onboarding, {
                let onboarding = UINavigationController(rootViewController: OnboardingViewController())
                onboarding.modalPresentationStyle = .fullScreen
                self.present(onboarding, animated: true, completion: nil)
            }),
            (LocalizedStrings.other_faq, CellImage.faq, { self.navigationController?.pushViewController(FaqViewController(), animated: true) }),
            (LocalizedStrings.other_about, CellImage.about, { self.navigationController?.pushViewController(AboutViewController(), animated: true) }),
        ]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: "init") {
            aboutCells[0].action()
        }
    }
    
    @objc func appMovedToBackground() {
        settings = Settings.reload()
        sections = Settings.buildSections()
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { lastSection + 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case lastSection: return aboutCells.count
        case 0, 1: return 1
        default:
            let sectionId = section - 2
            guard 0 <= sectionId && sectionId < sections.count else { return 0 }
            return sections[sectionId].options.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case lastSection: return LocalizedStrings.other
        case 0: return LocalizedStrings.installCantoboard
        case 1: return LocalizedStrings.testKeyboard
        default: return sections[section - 2].header
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return LocalizedStrings.installCantoboard_description
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case lastSection: return UITableViewCell(title: aboutCells[indexPath.row].title, image: aboutCells[indexPath.row].image)
        case 0: return UITableViewCell(tintedTitle: LocalizedStrings.installCantoboard_settings, image: CellImage.settings)
        case 1: return InputTableViewCell(tableView: tableView)
        default: return sections[indexPath.section - 2].options[indexPath.row].dequeueCell(with: self)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case lastSection: aboutCells[indexPath.row].action()
        case 0: UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        case 1: (tableView.cellForRow(at: indexPath) as? InputTableViewCell)?.showKeyboard()
        default: showDescription(of: sections[indexPath.section - 2].options[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: section)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DescriptionPresentationController(presentedViewController: presented, presenting: presentingViewController)
    }
    
    func showDescription(of option: Option) {
        guard option.videoUrl != nil || option.description != nil else { return }
        
        let description = UINavigationController(rootViewController: DescriptionViewController(option: option))
        description.modalPresentationStyle = .custom
        description.transitioningDelegate = self
        present(description, animated: true, completion: nil)
    }
}

class CellImage {
    private static let configuration = UIImage.SymbolConfiguration(pointSize: 20)
    private static let bundle = Bundle(for: CellImage.self)
    private static func imageAssets(_ key: String) -> UIImage {
        UIImage(systemName: key, withConfiguration: configuration) ?? UIImage(named: key, in: bundle, with: configuration)!
    }
    
    static let settings = imageAssets("gearshape")
    static let onboarding = imageAssets("arrow.uturn.right.circle")
    static let faq = imageAssets("questionmark.circle")
    static let about = imageAssets("info.circle")
    static let externalLink = imageAssets("arrow.up.right.circle")
    static let sourceCode = imageAssets("chevron.left.forwardslash.chevron.right")
    static let repository = imageAssets("book.closed")
    static let telegram = imageAssets("paperplane")
    static let email = imageAssets("envelope")
    static let rate = imageAssets("pencil")
}
