//
//  BaseViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit

class HomeTabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabBarItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupCenterButton()
    }
    
    func setupTabBarItems() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let workoutViewController = storyboard.instantiateViewController(withIdentifier: "WorkoutViewController")
        let exerciseListViewController = storyboard.instantiateViewController(withIdentifier: "ExerciseListViewController")
        let progressViewController = storyboard.instantiateViewController(withIdentifier: "ProgressViewController")
        let profileViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController")
        
        self.viewControllers = [
            createTabBarItem(tabImage: "WorkoutWhite", viewController: workoutViewController),
            createTabBarItem(tabImage: "ListWhite", viewController: exerciseListViewController),
            UIViewController(),
            createTabBarItem(tabImage: "MeasurementWhite", viewController: progressViewController),
            createTabBarItem(tabImage: "ProfileWhite", viewController: profileViewController)
        ]
        
        self.delegate = self
    }
    
    func setupCenterButton() {
        let bottomSafeArea = self.view.window?.safeAreaInsets.bottom ?? 0
        let buttonSize = CGFloat(45)
        let addButton = UIButton(frame: CGRect(x: view.bounds.width/2 - buttonSize/2,
                                               y: (view.bounds.height - buttonSize) - bottomSafeArea,
                                               width: buttonSize,
                                               height: buttonSize))
        addButton.layer.cornerRadius = 45
        addButton.setBackgroundImage(#imageLiteral(resourceName: "PlusWhite"), for: .normal)
        addButton.addTarget(self, action: #selector(tappAddButton(sender:)), for: .touchUpInside)
        
        view.addSubview(addButton)
        view.layoutIfNeeded()
    }
    
    func createTabBarItem(tabImage: String, viewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: viewController)
        let tabItem = UITabBarItem(title: viewController.title, image: UIImage(named: tabImage), selectedImage: UIImage(named: tabImage))
        viewController.tabBarItem = tabItem
        
        return navigationController
    }

    // MARK: - Actions
    @objc private func tappAddButton(sender: UIButton) {
        
    }
    
}

extension HomeTabBarViewController: UITabBarControllerDelegate {
   
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if (tabBarController.viewControllers != nil &&
            tabBarController.viewControllers!.count / 2 == tabBarController.viewControllers!.firstIndex(of: viewController)) {
            return false;
        }
        return true;
        
    }
    
}
