//
//  SettingsViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 30/5/22.
//

import UIKit

class SettingsViewController: SendoViewController {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size05
        static let optionStackHeight: CGFloat = 30
    }
    
    lazy var stackView: UIStackView = {
        let stackview = UIStackView()
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.addArrangedSubview(darkModeStackView)
        return stackview
    }()
    
    lazy var darkModeStackView: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .horizontal
        stackview.addArrangedSubview(darkModeLabel)
        stackview.addArrangedSubview(darkModeSwitch)
        return stackview
    }()
    
    lazy var darkModeLabel: UILabel = {
        let dmLabel = UILabel()
        dmLabel.text = "Dark mode"
        return dmLabel
    }()
    
    lazy var darkModeSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.addTarget(self, action: #selector(darkModeSwitchAction(_:)), for: .valueChanged)
        return toggle
    }()
    
    static func create() -> SettingsViewController {
        return SettingsViewController(title: "Settings")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        darkModeSwitch.setOn(UserDefaults.standard.bool(forKey: "darkMode"), animated: false)
    }
    
    override func loadView() {
        super.loadView()
        setupStackView()
    }
    
    private func setupStackView() {
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                           constant: Constants.margin),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                               constant: Constants.margin),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor,
                                                constant: Constants.margin),
        ])
    }
}

extension SettingsViewController {
    
    @objc private func darkModeSwitchAction(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "darkMode")
        let style = Self.preferredInterfaceStyle
        tabBarController?.overrideUserInterfaceStyle = style
        overrideUserInterfaceStyle = style
    }
}
