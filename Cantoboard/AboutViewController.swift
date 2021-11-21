//
//  AboutViewController.swift
//  Cantoboard
//
//  Created by Alex Man on 23/11/21.
//

import UIKit

class AboutViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let sections: [[(image: UIImage, title: String, url: String)]] = [
        [
            (CellImage.externalLink, LocalizedStrings.about_jyutpingSite, "https://jyutping.org"),
            (CellImage.sourceCode, LocalizedStrings.about_sourceCode, "https://github.com/Cantoboard/Cantoboard"),
        ],
        [
            (CellImage.repository, "Rime Input Method Engine", "https://github.com/rime/librime"),
            (CellImage.repository, "Rime Cantonese Input Schema", "https://github.com/rime/rime-cantonese"),
            (CellImage.repository, "Open Chinese Convert (OpenCC)", "https://github.com/BYVoid/OpenCC"),
            (CellImage.repository, "ISEmojiView", "https://github.com/isaced/ISEmojiView"),
        ],
        [
            (CellImage.telegram, LocalizedStrings.about_telegram, "https://t.me/cantoboard"),
            (CellImage.email, LocalizedStrings.about_email, "mailto:cantoboard@gmail.com"),
            (CellImage.rate, LocalizedStrings.about_appStore, "https://apps.apple.com/us/app/cantoboard/id1556817074"),
        ],
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizedStrings.other_about
        view.backgroundColor = .systemBackground
        let tableView = UITableView(frame: view.frame, style: .grouped)
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
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { Self.sections.count }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Self.sections[section].count }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return LocalizedStrings.about_credit
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Self.sections[indexPath.section][indexPath.row]
        return UITableViewCell(title: row.title, image: row.image)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let url = URL(string: Self.sections[indexPath.section][indexPath.row].url) {
            UIApplication.shared.open(url)
        }
    }
}
