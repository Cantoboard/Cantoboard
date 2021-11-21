//
//  FaqViewController.swift
//  Cantoboard
//
//  Created by Alex Man on 23/11/21.
//

import UIKit

class FaqViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let faqs: [(question: String, answer: String)] = [
        (LocalizedStrings.faq_0_question, LocalizedStrings.faq_0_answer),
        (LocalizedStrings.faq_1_question, LocalizedStrings.faq_1_answer),
        (LocalizedStrings.faq_2_question, LocalizedStrings.faq_2_answer),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizedStrings.other_faq
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
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Self.faqs.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let faq = Self.faqs[indexPath.row]
        return FaqTableViewCell(question: faq.question, answer: faq.answer)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let cell = tableView.cellForRow(at: indexPath) as! FaqTableViewCell
        cell.answerLabel.isHidden = !cell.answerLabel.isHidden
        cell.backgroundColor = .systemGray2
        UIView.animate(withDuration: 0.35) {
            tableView.performBatchUpdates(nil)
            cell.backgroundColor = .secondarySystemGroupedBackground
        }
    }
}

class FaqTableViewCell: UITableViewCell {
    var answerLabel: UILabel!
    
    convenience init(question: String, answer: String) {
        self.init()
        
        let questionLabel = UILabel()
        questionLabel.text = question
        questionLabel.font = .preferredFont(forTextStyle: .headline)
        questionLabel.numberOfLines = 0
        
        answerLabel = UILabel()
        answerLabel.text = answer
        answerLabel.font = .preferredFont(forTextStyle: .body)
        answerLabel.numberOfLines = 0
        answerLabel.isHidden = true
        
        let stackView = UIStackView(arrangedSubviews: [questionLabel, answerLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
        ])
        
        selectionStyle = .none
    }
}
