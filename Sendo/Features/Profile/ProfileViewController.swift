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
import FirebaseAuth
import GoogleSignIn

class ProfileViewController: BaseTabViewController {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size05
    }
    
    private lazy var loginView: ProfileLoginView = {
        let view = ProfileLoginView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tapLogginButtonSubject.sink { [weak self] type in
            guard let self else { return }
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
        let settings = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings(sender:)))
        settings.accessibilityLabel = "Settings"
        settings.accessibilityIdentifier = "profile.settings"
        navigationItem.rightBarButtonItem = settings
    }
    
    @objc func openSettings(sender: UIBarButtonItem) {
        let settingsVC = SettingsViewController.create()
        navigateToViewController(viewController: settingsVC)
    }
}

// MARK: - Authentications
private extension ProfileViewController {
    
    private func signInGoogle() {
        guard !AppEnvironment.usesFixtures else { return }
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            guard error == nil else { return }
            guard let result = result else { return }

            let user = result.user
            guard let idToken = user.idToken?.tokenString, let providerUserID = user.userID else { return }
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            self.firebaseLoad(credential: credential, providerUserID: providerUserID)
        }
    }
    
    private func signInApple() {
        guard !AppEnvironment.usesFixtures else { return }
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
    
    private func firebaseLoad(credential: AuthCredential, providerUserID: String) {
        guard let session = AppEnvironment.session else { return }
        Task {
            do {
                let account = try await session.signIn(with: credential, providerUserID: providerUserID)
                authViewModel.createUser(user: AuthUser(uid: account.uid, name: account.name))
            } catch {
                NSLog("Sendo couldn’t complete sign-in or a pending measurement transfer.")
            }
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
            
            let credential = OAuthProvider.appleCredential(withIDToken: appleIDTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
            firebaseLoad(credential: credential, providerUserID: appleIDCredential.user)
        }
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
