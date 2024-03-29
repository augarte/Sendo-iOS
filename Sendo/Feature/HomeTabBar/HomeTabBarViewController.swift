//
//  BaseViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit

class HomeTabBarViewController: UITabBarController {
    
    private var addButtonSelected: Bool = false
    private var addWorkout: UIButton?
    private var addProgress: UIButton?
    
    static func create() -> HomeTabBarViewController {
        return HomeTabBarViewController(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let preferences = UserDefaults.standard
        var darkMode = false
        if preferences.object(forKey: "darkMode") != nil {
            darkMode = preferences.bool(forKey: "darkMode")
        }
        overrideUserInterfaceStyle = darkMode ? .dark : .light
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //setupCenterButton()
        applyStyle()
    }
    
    private func applyStyle() {
        tabBar.backgroundColor = UIColor(named:"PrimaryColor")
        tabBar.barTintColor = UIColor(named:"PrimaryColor")
        view.backgroundColor = UIColor(named:"PrimaryColor")
        tabBar.barStyle = .black
    }
}

private extension HomeTabBarViewController {
    
    func setupTabBarItems() {
        let workoutVC = WorkoutViewController.create()
        let exerciseListVC = ExerciseListViewController.create()
        let progressVC = ProgressViewController.create()
        let profileVC = ProfileViewController.create()
        
        self.viewControllers = [
            createTabBarItem(title: workoutVC.titleName, tabImage: workoutVC.tabImage, viewController: workoutVC),
            createTabBarItem(title: exerciseListVC.titleName, tabImage: exerciseListVC.tabImage, viewController: exerciseListVC),
            //UIViewController(),
            createTabBarItem(title: progressVC.titleName, tabImage: progressVC.tabImage, viewController: progressVC),
            createTabBarItem(title: profileVC.titleName, tabImage: profileVC.tabImage, viewController: profileVC)
        ]
        //self.delegate = self
    }
    
    func createTabBarItem(title: String, tabImage: String, viewController: SendoViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: viewController)
        let tabItem = UITabBarItem(title: viewController.title, image: UIImage(named: tabImage), selectedImage: UIImage(named: tabImage))
        tabItem.title = title
        viewController.tabBarItem = tabItem
        
        return navigationController
    }
}

private extension HomeTabBarViewController {
    
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dissmissAddButton(sender:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func tappAddButton(sender: UIButton) {
        addButtonSelected = !addButtonSelected
        if addButtonSelected {
            //Workout adding button
            addWorkout = UIButton(frame: CGRect(x: sender.frame.origin.x - 40,
                                                y: sender.frame.origin.y - 64,
                                                width: sender.frame.size.width,
                                                height: sender.frame.size.height))
            guard let addWorkout = addWorkout else { return }
            addWorkout.layer.cornerRadius = sender.frame.size.width / 2
            addWorkout.setBackgroundImage(#imageLiteral(resourceName: "WorkoutWhite"), for: .normal)
            addWorkout.backgroundColor = UIColor(named: "PrimaryColor")
            view.addSubview(addWorkout)
            view.layoutIfNeeded()
            
            //Measurement adding button
            addProgress = UIButton(frame: CGRect(x: sender.frame.origin.x + 40,
                                                 y: sender.frame.origin.y - 64,
                                                 width: sender.frame.size.width,
                                                 height: sender.frame.size.height))
            guard let addProgress = addProgress else { return }
            addProgress.layer.cornerRadius = sender.frame.size.width / 2
            addProgress.setBackgroundImage(#imageLiteral(resourceName: "MeasurementWhite"), for: .normal)
            addProgress.backgroundColor = UIColor(named: "PrimaryColor")
            view.addSubview(addProgress)
            view.layoutIfNeeded()
        } else {
            self.dissmissAddButton(sender: sender)
        }
    }
    
    @objc private func dissmissAddButton(sender: UIButton?) {
        addWorkout?.removeFromSuperview()
        addProgress?.removeFromSuperview()
    }
}

//extension HomeTabBarViewController: UITabBarControllerDelegate {
//
//    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
//        if (tabBarController.viewControllers != nil &&
//            tabBarController.viewControllers!.count / 2 == tabBarController.viewControllers!.firstIndex(of: viewController)) {
//            return false;
//        }
//        return true;
//    }
//}
