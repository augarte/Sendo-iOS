//
//  NewEntryDialog.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/6/22.
//

import UIKit

class NewEntryDialog: SendoViewController {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size05
        static let stackBackground: UIColor = .white.withAlphaComponent(0.2)
        static let stackConrners: CGFloat = 8
    }
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(entryDate)
        stack.addArrangedSubview(entryValue)
        return stack
    }()
    
    private lazy var entryDate: NewEntryLine = {
        let label = NewEntryLine()
        label.setup(title: "Date", type: .date)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var entryValue: NewEntryLine = {
        let field = NewEntryLine()
        if let measurement = measurement {
            field.setup(title: "Value", type: .double, value: String(measurement.value))
        } else {
            field.setup(title: "Value", type: .double, placeHolder: "90.0")
        }
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private var measurement: Measurement?
    private var completion: ((Measurement) -> ())?
    private let dataType = "Weight"
    
    static func create(measurement: Measurement? = nil, completion: @escaping (Measurement) -> ()) -> NewEntryDialog {
        let newEntryDialog = NewEntryDialog(title: "New Entry")
        newEntryDialog.measurement = measurement
        newEntryDialog.completion = completion
        return newEntryDialog
    }
    
    override func loadView() {
        super.loadView()
        addToolbar()
        setupStackView()
    }
    
    private func setupStackView() {
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.margin),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.margin),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: Constants.margin),
        ])
        stackView.backgroundColor = Constants.stackBackground
        stackView.layer.cornerRadius = Constants.stackConrners
    }
}

// MARK: - Toolbar
extension NewEntryDialog {

    private func addToolbar(){
        self.navigationItem.title = dataType
        let cancelBtn = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancel))
        self.navigationItem.setLeftBarButton(cancelBtn, animated: false)
        let addBtn = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(addEntry))
        self.navigationItem.setRightBarButton(addBtn, animated: false)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func addEntry(_ sender: Any) {
        if let completion = completion {
            let timestamp = String(Int(NSDate().timeIntervalSince1970))
            let value = Double(entryValue.entryField.text ?? "0.0") ?? 0.0
            let newEntry = Measurement(date: timestamp, value: value)
            completion(newEntry)
        }
        dismiss(animated: true)
    }
}
