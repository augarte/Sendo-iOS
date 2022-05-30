//
//  SettingsView.swift
//  Sendo
//
//  Created by Aimar Ugarte on 30/5/22.
//

import UIKit

class SettingsView: SendoViewController {
    
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    private var darkMode = false
    
    static func create() -> SettingsView {
        return SettingsView(title: "Settings", nibName: SettingsView.typeName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "darkMode") == nil {
            //  Doesn't exist
        } else {
            darkMode = preferences.bool(forKey: "darkMode")
            darkModeSwitch.setOn(darkMode, animated: false)
            
        }
    }

    @IBAction func darkModeSwitchAction(_ sender: Any) {
        let preferences = UserDefaults.standard
        preferences.set(!darkMode, forKey: "darkMode")
        preferences.synchronize()
    }

}
