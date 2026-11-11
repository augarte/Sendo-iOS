import SwiftUI

enum SendoPalette {
    static let paper = adaptive(0xF9F8F5, 0x17191D)
    static let ink = adaptive(0x20232A, 0xF3F2F0)
    static let subdued = adaptive(0x595F6C, 0xB0B7C6)
    static let line = adaptive(0xDEDFDC, 0x3A404C)
    static let panel = adaptive(0xEFEEE9, 0x222630)
    static let quiet = adaptive(0xE6EAFA, 0x262E4B)
    static let accent = adaptive(0x294BB0, 0xB9C8FF)
    static let action = adaptive(0x253F92, 0xBECAFF)
    static let actionInk = adaptive(0xFFFFFF, 0x152149)
    static let error = adaptive(0xA22233, 0xFFB3B9)

    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat(hex >> 16) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
}

struct SendoPage<Content: View>: View {
    let title: String
    var context: String? = nil
    var eyebrow: String? = nil
    var subtitle: String? = nil
    var back: (title: String, action: () -> Void)? = nil
    @ViewBuilder var content: () -> Content
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 30.0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let back {
                    Button(back.title, action: back.action)
                        .buttonStyle(SendoButtonStyle(.link))
                } else {
                    Text("Sendo")
                        .font(.title3.bold())
                        .lineLimit(1)
                        .fixedSize()
                        .layoutPriority(1)
                        .accessibilityIdentifier("sendo.wordmark")
                }
                SwiftUI.Spacer()
                if let context {
                    Text(context).font(.footnote).foregroundStyle(SendoPalette.subdued).monospacedDigit()
                }
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let eyebrow { SendoEyebrow(text: eyebrow) }
                        Text(title)
                            .font(.system(size: titleSize, weight: .bold))
                            .tracking(-1)
                            .accessibilityAddTraits(.isHeader)
                        if let subtitle {
                            Text(subtitle).font(.subheadline).foregroundStyle(SendoPalette.subdued)
                        }
                    }
                    content()
                }
                .frame(maxWidth: 520, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(SendoPalette.ink)
        .tint(SendoPalette.accent)
        .background(SendoPalette.paper.ignoresSafeArea())
    }
}

struct SendoEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1)
            .foregroundStyle(SendoPalette.accent)
    }
}

struct SendoButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, link }

    private let kind: Kind

    init(_ kind: Kind) { self.kind = kind }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(kind == .primary ? SendoPalette.actionInk : SendoPalette.accent)
            .padding(.horizontal, kind == .link ? 3 : 10)
            .padding(.vertical, 8)
            .frame(maxWidth: kind == .link ? nil : .infinity, minHeight: 44)
            .background(kind == .primary ? SendoPalette.action : .clear, in: .rect(cornerRadius: 9))
            .overlay {
                if kind == .secondary { RoundedRectangle(cornerRadius: 9).strokeBorder(SendoPalette.line) }
            }
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

struct SendoEmptyState: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(SendoPalette.accent)
                .frame(width: 42, height: 42)
                .background(SendoPalette.quiet, in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)
            Text(title).font(.headline)
            Text(detail).foregroundStyle(SendoPalette.subdued)
        }
        .padding(.top, 12)
    }
}

struct SendoPanel: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(SendoPalette.panel, in: .rect(cornerRadius: 13))
    }
}

struct SendoField<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.footnote.weight(.semibold))
            content()
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .overlay { RoundedRectangle(cornerRadius: 9).strokeBorder(SendoPalette.line).allowsHitTesting(false) }
        }
    }
}

class SendoHostingController<Content: View>: UIHostingController<Content> {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}

extension UIViewController {
    func embedSendoScreen<Content: View>(_ screen: UIHostingController<Content>) {
        addChild(screen)
        screen.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(screen.view)
        NSLayoutConstraint.activate([
            screen.view.topAnchor.constraint(equalTo: view.topAnchor),
            screen.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            screen.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            screen.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        screen.didMove(toParent: self)
    }
}
