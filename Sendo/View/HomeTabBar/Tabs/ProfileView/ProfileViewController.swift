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
import AuthenticationServices

class ProfileViewController: BaseTabViewController {
    
    @IBOutlet weak var googleSignin: GIDSignInButton!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    private var currentNonce: String?
    private var darkMode = false
    
    static func create() -> ProfileViewController {
        return ProfileViewController(title: "Profile", image: "ProfileWhite", nibName: ProfileViewController.typeName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    

    // MARK: Authentications
    @IBAction func appleSigninPress(_ sender: Any) {
        currentNonce = Utils.randomNonceString()
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = Utils.sha256(currentNonce!)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
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
    
    @objc func mailSigninPress(_ sender: Any) {
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

extension ProfileViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let nonce = currentNonce,
           let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let appleIDToken = appleIDCredential.identityToken,
           let appleIDTokenString = String(data: appleIDToken, encoding: .utf8){
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: appleIDTokenString, rawNonce: nonce)
            firebaseLoad(credential: credential)
        }
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
    
}
