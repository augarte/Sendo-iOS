//
//  ProfileViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 13/11/21.
//

import UIKit
import Combine
import AuthenticationServices
import Firebase
import GoogleSignIn

class ProfileViewController: BaseTabViewController {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size05
    }
    
    private lazy var loginView: ProfileLoginView = {
        let view = ProfileLoginView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.buttonPressedSubject.sink { type in
            switch type {
            case .google: self.signInGoogle()
            case .apple: self.signInApple()
            }
        }
        .store(in: &cancellBag)
        return view
    }()
    
    private var currentNonce: String?
    private var cancellBag = Set<AnyCancellable>()
    private let authViewModel = AuthViewModel()
    
    static func create() -> ProfileViewController {
        return ProfileViewController(title: "Profile", image: "ProfileWhite")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        authViewModel.authUser.sink { [weak self] (_) in
            guard let authUser = self?.authViewModel.authUser.value else { return }
            self?.title = authUser.name
        }.store(in: &cancellBag)
    }
    
    override func loadView() {
        super.loadView()
        addToolbarItem()
        setupLoginView()
    }
    
    private func setupLoginView() {
        view.addSubview(loginView)
        NSLayoutConstraint.activate([
            loginView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loginView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loginView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loginView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        loginView.setupView()
    }
}

// MARK: - Toolbar
private extension ProfileViewController {
    
    func addToolbarItem(){
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(self.openSettings(sender:)))
    }
    
    @objc func openSettings(sender: UIBarButtonItem) {
        let settingsVC = SettingsViewController.create()
        navigateToViewController(viewController: settingsVC)
    }
}

// MARK: - Authentications
private extension ProfileViewController {
    
    private func signInGoogle() {
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
    
    private func signInApple() {
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
    
    private func firebaseLoad(credential: AuthCredential){
        Auth.auth().signIn(with: credential) { authResult, error in
            guard error == nil else { return }
            guard let uid = authResult?.user.uid else { return }
            
            let newUser = AuthUser(uid: uid, name: authResult?.user.displayName)
            self.authViewModel.createUser(user: newUser)
        }
    }
    
    private func logout(){
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
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
