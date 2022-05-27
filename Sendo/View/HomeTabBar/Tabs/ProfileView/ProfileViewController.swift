//
//  ProfileViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 13/11/21.
//

import UIKit
import Combine
import Firebase
import GoogleSignIn

class ProfileViewController: SendoViewController {
    
    @IBOutlet weak var googleSignin: GIDSignInButton!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    var darkMode = false
    
    static func create() -> ProfileViewController {
        return ProfileViewController(nibName: ProfileViewController.typeName, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Profile"
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.googleSigninPress (_:)))
        self.googleSignin.addGestureRecognizer(gesture)

                
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
    
    @objc func googleSigninPress(_ sender:UITapGestureRecognizer){
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(
            with: config,
            presenting: self
        ) { user, error in
            guard error == nil else { return }
            guard let user = user else { return }
           
            let authentication = user.authentication
            let accessToken = authentication.accessToken
            guard let idToken = authentication.idToken else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            self.firebaseLoad(credential: credential)
       } 
    }
    
    @objc func appleSigninPress(_ sender:UITapGestureRecognizer){
    }
    
    @objc func mailSigninPress(_ sender:UITapGestureRecognizer){
    }
    
    func firebaseLoad(credential: AuthCredential){
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
            }
            
        }
    }
    
    func logout(){
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
}
