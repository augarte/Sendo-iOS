import AuthenticationServices
import SwiftUI

/// Sign-in buttons that follow Sendo's button shape. Both providers keep their required logo and wording:
/// Apple's system button, and Google's unmodified "G" with the "Sign in with Google" label.
struct ProfileLoginView: View {
    enum LoginType {
        case google
        case apple
    }

    let onSignIn: (LoginType) -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 10) {
            AppleAuthorizationButton(style: onBoneHero ? .black : .white) { onSignIn(.apple) }
                .id(scheme)
                .frame(height: 52)
            googleButton
        }
    }

    /// The account hero is bone in dark mode and black in light mode, so each provider uses its matching theme.
    private var onBoneHero: Bool { scheme == .dark }

    private var googleButton: some View {
        Button { onSignIn(.google) } label: {
            HStack(spacing: 10) {
                Image("GoogleG").resizable().frame(width: 18, height: 18).accessibilityHidden(true)
                Text("Sign in with Google").font(.system(size: 17, weight: .medium))
            }
            .foregroundStyle(onBoneHero ? rgb(0xE3E3E3) : rgb(0x1F1F1F))
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(onBoneHero ? rgb(0x131314) : rgb(0xFFFFFF), in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(onBoneHero ? rgb(0x8E918F) : rgb(0x747775), lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func rgb(_ hex: UInt32) -> Color {
        Color(red: Double(hex >> 16) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }
}
