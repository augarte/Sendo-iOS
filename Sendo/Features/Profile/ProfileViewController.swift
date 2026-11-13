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
            photoURL: account?.isGuest == false ? account?.photoURL : nil,
            training: trainingState(),
            onEdit: { [weak self] in self?.editTraining() },
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
    let photoURL: URL?
    let training: WorkoutTrainingState?
    let onEdit: () -> Void
    let onSignIn: (ProfileLoginView.LoginType) -> Void
    @State private var isDark = SendoAppearance.isDark

    var body: some View {
        SendoPage(title: "Profile") {
            let accountName = signedIn ? (name ?? "Signed in") : "Training as a guest"
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    if signedIn, let initial = accountName.first {
                        avatar(initial: initial)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        SendoEyebrow(text: "Account", color: SendoPalette.heroSubdued)
                        SendoDisplayText(accountName, size: 36, relativeTo: .title)
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                    }
                }
                if !signedIn {
                    Text("Sign in to sync your measurements across devices.")
                        .font(.footnote).foregroundStyle(SendoPalette.heroSubdued)
                    ProfileLoginView(onSignIn: onSignIn)
                }
            }
            .modifier(SendoHero())
            HStack(spacing: 12) {
                tile("Training days", value: training?.weeklyTrainingDays.map(String.init) ?? "Not set")
                tile("Equipment", value: training?.equipment?.title ?? "Not set")
            }
            Button("Edit training preferences", action: onEdit).buttonStyle(SendoButtonStyle(.secondary))
        }
        .overlay(alignment: .topTrailing) {
            Button {
                isDark.toggle()
                SendoAppearance.setDark(isDark)
            } label: {
                Image(systemName: isDark ? "sun.max" : "moon")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
            .accessibilityLabel(isDark ? "Switch to light mode" : "Switch to dark mode")
            .accessibilityIdentifier("profile.darkMode")
        }
    }

    /// The account photo when the provider gives one, over the name's initial so there is never an empty circle.
    private func avatar(initial: Character) -> some View {
        ZStack {
            Circle().fill(SendoPalette.heroInk)
            Text(String(initial))
                .font(.system(size: 34, weight: .black).width(.compressed))
                .textCase(.uppercase)
                .foregroundStyle(SendoPalette.hero)
            if let photoURL {
                AsyncImage(url: photoURL) { phase in
                    if case .success(let image) = phase { image.resizable().scaledToFill() }
                }
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }

    private func tile(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SendoDisplayText(value, size: 64, relativeTo: .largeTitle)
                .minimumScaleFactor(0.35)
                .lineLimit(1)
                .frame(height: 64, alignment: .bottomLeading)
            Text(title).font(.subheadline).foregroundStyle(SendoPalette.subdued)
        }
        .modifier(SendoPanel())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
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
