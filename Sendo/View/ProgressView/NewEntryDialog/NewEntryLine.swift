//
//  NewEntryLine.swift
//  Sendo
//
//  Created by Aimar Ugarte on 4/11/22.
//

import UIKit
import Combine

enum NewEntryType: Int {
    case date
    case double
    case text
}

class NewEntryLine: UIView {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size04
        static let viewHeight: CGFloat = 40
    }
    
    private var type: NewEntryType = .double
    
    private lazy var entryTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var entryField: UITextField = {
        let field = UITextField()
        field.textAlignment = .right
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyle()
    }
    
    func setup(title: String, type: NewEntryType, placeHolder: String) {
        entryField.placeholder = placeHolder
        setup(title: title, type: type)
    }
    
    func setup(title: String, type: NewEntryType, value: String) {
        entryField.text = value
        setup(title: title, type: type)
    }
    
    func setup(title: String, type: NewEntryType) {
        self.type = type
        entryTitle.text = title
        applyStyle()
        if type == .date {
            showDatePicker()
        }
    }
    
    private func applyStyle() {
        setConstraints()
    }
    
    private func setConstraints() {
        addSubviews([entryTitle, entryField])
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Constants.viewHeight),
            entryTitle.topAnchor.constraint(equalTo: topAnchor),
            entryTitle.bottomAnchor.constraint(equalTo: bottomAnchor),
            entryTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.margin),
            entryField.leadingAnchor.constraint(equalTo: entryTitle.trailingAnchor, constant: Constants.margin),
            entryField.topAnchor.constraint(equalTo: topAnchor),
            entryField.bottomAnchor.constraint(equalTo: bottomAnchor),
            trailingAnchor.constraint(equalTo: entryField.trailingAnchor, constant: Constants.margin),
        ])
        entryTitle.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
}

private extension NewEntryLine{
    
    func showDatePicker() {
        let datePicker = UIDatePicker()
        datePicker.date = Date()
        datePicker.locale = .current
        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        }
        datePicker.addTarget(self, action: #selector(handleDateSelection), for: .valueChanged)
        entryField.inputView = datePicker
        setDate(date: Date())
    }
    
    @objc func handleDateSelection(picker: UIDatePicker) {
        setDate(date: picker.date)
    }
    
    func setDate(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        entryField.text = dateFormatter.string(from: date)
    }
}

extension NewEntryLine: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        type != .date
    }
}
