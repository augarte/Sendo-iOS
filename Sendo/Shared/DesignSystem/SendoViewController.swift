//
//  BaseViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import SwiftUI

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
        view.backgroundColor = UIColor(SendoPalette.paper)
        view.tintColor = UIColor(SendoPalette.accent)
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
        present(nvc, animated: true)
    }
}


/// The app's light/dark choice. It is applied to the window once, so every screen and sheet follows without
/// each view controller overriding its own trait collection.
enum SendoAppearance {
    private static let key = "darkMode"

    static var isDark: Bool { UserDefaults.standard.bool(forKey: key) }
    static var interfaceStyle: UIUserInterfaceStyle { isDark ? .dark : .light }

    @MainActor
    static func setDark(_ dark: Bool) {
        UserDefaults.standard.set(dark, forKey: key)
        let windows = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
        for window in windows {
            UIView.transition(with: window, duration: 0.2, options: .transitionCrossDissolve) {
                window.overrideUserInterfaceStyle = interfaceStyle
            }
        }
    }
}
