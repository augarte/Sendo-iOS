//
//  BaseViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit

class SendoViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.init(named:"PrimaryColor")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let preferences = UserDefaults.standard
        var darkMode = false
        if preferences.object(forKey: "darkMode") != nil {
            darkMode = preferences.bool(forKey: "darkMode")
        }
        overrideUserInterfaceStyle = darkMode ? .dark : .light
        
    }
    
    func navigateToViewController(viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func showModalView(viewController: UIViewController) {
        viewController.modalPresentationStyle = .automatic
        present(viewController, animated: true)
    }

}
