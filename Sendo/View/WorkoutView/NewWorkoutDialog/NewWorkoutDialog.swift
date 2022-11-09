//
//  NewWorkoutDialog.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/11/22.
//

import Foundation

import UIKit

class NewWorkoutDialog: SendoViewController {
    
    private lazy var tableview: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        return table
    }()
    
    private var completion: (() -> ())?
    
    static func create(completion: @escaping () -> ()) -> NewWorkoutDialog {
        let newWorkoutDialog = NewWorkoutDialog(title: "New Workout")
        newWorkoutDialog.completion = completion
        return newWorkoutDialog
    }
    
    override func loadView() {
        super.loadView()
        setupTable()
    }
    
    private func setupTable() {
        view.addSubview(tableview)
        NSLayoutConstraint.activate([
            tableview.topAnchor.constraint(equalTo: view.topAnchor),
            tableview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableview.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(SessionTableViewCell.self, forCellReuseIdentifier: SessionTableViewCell.typeName)
    }
}

extension NewWorkoutDialog: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SessionTableViewCell.typeName)! as! SessionTableViewCell
        cell.configureCell()
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let stack = UIStackView()
        let button = UIButton()
        button.titleLabel?.text = "Add new session"
        stack.addArrangedSubview(button)
        button.backgroundColor = .red
        return stack
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = SessionEditorViewController.create {
            
        }
        navigateToViewController(viewController: vc)
    }
}
