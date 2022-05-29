//
//  BaseViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit

open class SendoViewController: UIViewController {
    
    final let titleName: String
        
    init(title: String, nibName: String) {
        titleName = title
        super.init(nibName: nibName, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        title = titleName
        view.backgroundColor = UIColor.init(named:"PrimaryColor")
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        
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
