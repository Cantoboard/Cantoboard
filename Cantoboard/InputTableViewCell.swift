//
//  InputTableViewCell.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import UIKit

class InputTableViewCell: UITableViewCell, UITextFieldDelegate {
    private var tableView: UITableView!
    private var textField: UITextField!

    convenience init(tableView: UITableView) {
        self.init()
        self.tableView = tableView
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGestureRecognizer)
        textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.returnKeyType = .done
        textField.placeholder = LocalizedStrings.testKeyboard_placeholder
        textField.font = .preferredFont(forTextStyle: .body)
        textField.delegate = self
        contentView.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            contentView.bottomAnchor.constraint(equalTo: textField.bottomAnchor, constant: 10),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 20),
        ])
        selectionStyle = .none
    }
    
    func showKeyboard() {
        textField.becomeFirstResponder()
    }
    
    @objc func hideKeyboard() {
        textField.text = ""
        tableView.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        textField.text = ""
        return true
    }
}
