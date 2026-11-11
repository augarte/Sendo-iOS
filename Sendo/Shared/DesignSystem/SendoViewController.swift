//
//  BaseViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit

open class SendoViewController: UIViewController {
    
    final let titleName: String
    
    init(title: String) {
        titleName = title
        super.init(nibName: nil, bundle: nil)
    }
    
    init(title: String, nibName: String) {
        titleName = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        title = titleName
        view.backgroundColor = UIColor(named:"PrimaryColor")
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        overrideUserInterfaceStyle = Self.preferredInterfaceStyle
    }
    static var preferredInterfaceStyle: UIUserInterfaceStyle {
        UserDefaults.standard.bool(forKey: "darkMode") ? .dark : .light
    }

}

// MARK: - Navigation
extension SendoViewController {
    
    func navigateToViewController(viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func showModalView(viewController: UIViewController) {
        viewController.modalPresentationStyle = .automatic
        let nvc = UINavigationController(rootViewController: viewController)
        nvc.overrideUserInterfaceStyle = Self.preferredInterfaceStyle
        present(nvc, animated: true)
    }
}
