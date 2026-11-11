//
//  ProfileViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 13/11/21.
//

import SwiftUI
import Combine
import AuthenticationServices
import Firebase
import FirebaseAuth
import GoogleSignIn

class ProfileViewController: BaseTabViewController {
    
    var trainingState: () -> WorkoutTrainingState? = { nil }
    var editTraining: () -> Void = {}
    private var screen: UIHostingController<ProfileScreen>?
    private var account: FirebaseSessionStore.Account?

    private var currentNonce: String?
    private var cancellBag = Set<AnyCancellable>()
    private let authViewModel = AuthViewModel()
    
    static func create() -> ProfileViewController {
        return ProfileViewController(title: "Profile", image: "ProfileWhite")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        AppEnvironment.session?.$account.sink { [weak self] account in
            self?.account = account
            self?.render()
        }.store(in: &cancellBag)
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        render()
    }

    private func render() {
        let content = ProfileScreen(
            name: account?.isGuest == false ? account?.name : nil,
            signedIn: account?.isGuest == false,
            training: trainingState(),
            onEdit: { [weak self] in self?.editTraining() },
            onSettings: { [weak self] in self?.navigateToViewController(viewController: SettingsViewController.create()) },
            onSignIn: { [weak self] type in
                switch type {
                case .google: self?.signInGoogle()
                case .apple: self?.signInApple()
                }
            }
        )
        if let screen {
            screen.rootView = content
        } else {
            let screen = UIHostingController(rootView: content)
            embedSendoScreen(screen)
            self.screen = screen
        }
    }
}

private struct ProfileScreen: View {
    let name: String?
    let signedIn: Bool
    let training: WorkoutTrainingState?
    let onEdit: () -> Void
    let onSettings: () -> Void
    let onSignIn: (ProfileLoginView.LoginType) -> Void

    var body: some View {
        SendoPage(title: "Profile", context: "Preferences") {
            VStack(alignment: .leading, spacing: 7) {
                SendoEyebrow(text: "Account")
                Text(signedIn ? (name ?? "Signed in") : "Training as a guest").font(.headline)
                if !signedIn {
                    Text("Sign in to sync your measurements across devices.")
                        .font(.footnote).foregroundStyle(SendoPalette.subdued)
                    ProviderButtons(onSignIn: onSignIn).frame(height: 104).padding(.top, 4)
                }
            }
            .modifier(SendoPanel())
            row("Training days", value: training?.weeklyTrainingDays.map(String.init) ?? "Not set")
            row("Equipment", value: training?.equipment?.title ?? "Not set")
            Button("Edit training preferences", action: onEdit).buttonStyle(SendoButtonStyle(.link))
            Button("Settings", action: onSettings)
                .buttonStyle(SendoButtonStyle(.link))
                .accessibilityIdentifier("profile.settings")
        }
    }

    private func row(_ title: String, value: String) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                SwiftUI.Spacer()
                Text(value).font(.footnote).foregroundStyle(SendoPalette.subdued)
            }
            Divider().overlay(SendoPalette.line)
        }
    }
}

private struct ProviderButtons: UIViewRepresentable {
    let onSignIn: (ProfileLoginView.LoginType) -> Void

    final class Coordinator {
        var subscription: AnyCancellable?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ProfileLoginView {
        let view = ProfileLoginView()
        view.setupView()
        return view
    }

    func updateUIView(_ view: ProfileLoginView, context: Context) {
        context.coordinator.subscription = view.tapLogginButtonSubject.sink(receiveValue: onSignIn)
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
