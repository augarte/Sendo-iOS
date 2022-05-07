//
//  ProfileViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 13/11/21.
//

import UIKit
import Combine

class ProfileViewController: SendoViewController {
    
    @IBOutlet weak var darkModeSwitch: UISwitch!
    var darkMode = false
    
    static func create() -> ProfileViewController {
        return ProfileViewController(nibName: ProfileViewController.typeName, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Profile"
        
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "darkMode") == nil {
            //  Doesn't exist
        } else {
            darkMode = preferences.bool(forKey: "darkMode")
            darkModeSwitch.setOn(darkMode, animated: false)
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }

    @IBAction func darkModeSwitchAction(_ sender: Any) {
        let preferences = UserDefaults.standard
        preferences.set(!darkMode, forKey: "darkMode")
        preferences.synchronize()
    }
    
}
