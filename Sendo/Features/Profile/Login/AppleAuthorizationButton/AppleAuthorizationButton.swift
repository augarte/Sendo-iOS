import AuthenticationServices
import SwiftUI

/// The system Sign in with Apple button. It keeps Apple's required logo and wording; only the corner radius follows Sendo's buttons.
struct AppleAuthorizationButton: UIViewRepresentable {
    let style: ASAuthorizationAppleIDButton.Style
    let action: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: style)
        button.cornerRadius = 12
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ button: ASAuthorizationAppleIDButton, context: Context) {
        context.coordinator.action = action
    }

    final class Coordinator: NSObject {
        var action: () -> Void = {}

        @objc func tapped() { action() }
    }
}
