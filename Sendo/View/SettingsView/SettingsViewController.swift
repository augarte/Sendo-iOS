//
//  SettingsViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 30/5/22.
//

import UIKit
import Combine

class SettingsViewController: SendoViewController {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size05
        static let optionStackHeight: CGFloat = 30
    }
    
    lazy var stackView: UIStackView = {
        let stackview = UIStackView()
        stackview.translatesAutoresizingMaskIntoConstraints = false
        return stackview
    }()
    
    lazy var darkModeStackView: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .horizontal
        stackview.addArrangedSubview(darkModeLabel)
        stackview.addArrangedSubview(darkModeSwitch)
        stackview.translatesAutoresizingMaskIntoConstraints = false
        return stackview
    }()
    
    lazy var darkModeLabel: UILabel = {
        let dmLabel = UILabel()
        dmLabel.text = "Dark mode"
        dmLabel.translatesAutoresizingMaskIntoConstraints = false
        return dmLabel
    }()
    
    lazy var darkModeSwitch: UISwitch = {
        let dmSwitch = UISwitch()
        dmSwitch.translatesAutoresizingMaskIntoConstraints = false
        return dmSwitch
    }()
    
    private var myCancellable: AnyCancellable?
    private var darkMode = false
    
    static func create() -> SettingsViewController {
        return SettingsViewController(title: "Settings")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "darkMode") == nil {
            preferences.set(darkMode, forKey: "darkMode")
        } else {
            darkMode = preferences.bool(forKey: "darkMode")
        }
        darkModeSwitch.setOn(darkMode, animated: false)
    }
    
    override func loadView() {
        super.loadView()
        setupStackView()
    }
    
    private func setupStackView() {
        stackView.addArrangedSubview(darkModeStackView)
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                           constant: Constants.margin),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            darkModeStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor,
                                                       constant: Constants.margin),
            darkModeStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor,
                                                        constant: -Constants.margin)
        ])
    }
}

extension SettingsViewController {
    
    @IBAction func darkModeSwitchAction(_ sender: Any) {
        let preferences = UserDefaults.standard
        preferences.set(!darkMode, forKey: "darkMode")
        preferences.synchronize()
    }
}
