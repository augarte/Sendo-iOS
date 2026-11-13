import SwiftUI

enum SendoPalette {
    static let paper = adaptive(0xF1ECE2, 0x1B1C20)
    static let ink = adaptive(0x121212, 0xF2EEE6)
    static let subdued = adaptive(0x5E5A52, 0xB0ADA6)
    static let line = adaptive(0xCFC8BA, 0x3A3B43)
    static let panel = adaptive(0xFBF9F4, 0x27282E)
    static let quiet = adaptive(0xE4DDCF, 0x34353C)
    static let accent = adaptive(0x121212, 0xF2EEE6)
    static let action = adaptive(0x121212, 0xF2EEE6)
    static let actionInk = adaptive(0xF1ECE2, 0x1B1C20)
    static let error = adaptive(0xB3261E, 0xFF9A8F)

    static let hero = adaptive(0x121212, 0xF2EEE6)
    static let heroInk = adaptive(0xF2EEE6, 0x0D0D0E)
    static let heroSubdued = adaptive(0xA3A09A, 0x5E5A52)

    static let plateInk = Color(uiColor: color(0x0D0D0E))
    static let plateOutline = adaptive(0x121212, 0x121212, darkAlpha: 0)

    /// Competition-plate colours that sessions take by rotation position until the user picks their own.
    static let plateHexes: [UInt32] = [0xFF4B3A, 0x6FA8FF, 0xFFC93A, 0xFFFFFF, 0xAEB4BF]
    /// Suggested session colours, in the order the picker shows them.
    static let suggestions: [(name: String, hex: UInt32)] = [
        ("Red", 0xFF4B3A), ("Orange", 0xFF8A3D), ("Yellow", 0xFFC93A), ("Blue", 0x6FA8FF),
        ("Violet", 0xB58CFF), ("Pink", 0xFF7AB6), ("White", 0xFFFFFF), ("Grey", 0xAEB4BF)
    ]

    static func hexString(from color: Color) -> String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: nil)
        return String(format: "%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }

    private static func adaptive(_ light: UInt32, _ dark: UInt32, darkAlpha: CGFloat = 1) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? color(dark, alpha: darkAlpha) : color(light)
        })
    }

    fileprivate static func color(_ hex: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat(hex >> 16) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: alpha)
    }
}

/// A session's colour and a readable ink for text drawn on it, so any custom colour stays legible.
struct SendoSessionColor {
    let fill: Color
    let ink: Color

    init(hex: String?, index: Int) {
        let plates = SendoPalette.plateHexes
        let value = hex.flatMap { $0.count == 6 ? UInt32($0, radix: 16) : nil } ?? plates[index % plates.count]
        fill = Color(uiColor: SendoPalette.color(value))
        ink = Self.luminance(value) > 0.179 ? SendoPalette.plateInk : Color.white
    }

    private static func luminance(_ hex: UInt32) -> Double {
        func linear(_ component: UInt32) -> Double {
            let value = Double(component) / 255
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(hex >> 16) + 0.7152 * linear((hex >> 8) & 255) + 0.0722 * linear(hex & 255)
    }
}

/// Uppercase condensed display type. The accessibility label keeps the original casing so VoiceOver and UI tests read the real text.
struct SendoDisplayText: View {
    private let text: String
    private let weight: Font.Weight
    @ScaledMetric private var size: CGFloat

    init(_ text: String, size: CGFloat, weight: Font.Weight = .black, relativeTo style: Font.TextStyle = .title) {
        self.text = text
        self.weight = weight
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: weight).width(.compressed).leading(.tight))
            .textCase(.uppercase)
            .accessibilityLabel(text)
    }
}

struct SendoPage<Content: View>: View {
    let title: String
    var context: String? = nil
    var eyebrow: String? = nil
    var subtitle: String? = nil
    var back: (title: String, action: () -> Void)? = nil
    var backIcon: String? = nil
    var titleSize: CGFloat = 54
    var titleLines = 2
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let back, let backIcon {
                    Button(action: back.action) {
                        HStack(spacing: 4) {
                            Image(systemName: backIcon).font(.body.weight(.bold))
                            Text(back.title).font(.body.weight(.semibold))
                        }
                        .padding(.trailing, 8)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                } else if let back {
                    Button(back.title, action: back.action)
                        .buttonStyle(SendoButtonStyle(.link))
                } else {
                    SendoDisplayText("Sendo", size: 24, relativeTo: .title3)
                        .tracking(1.5)
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
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let eyebrow { SendoEyebrow(text: eyebrow) }
                        SendoDisplayText(title, size: titleSize, relativeTo: .largeTitle)
                            .minimumScaleFactor(0.6)
                            .lineLimit(titleLines)
                            .accessibilityAddTraits(.isHeader)
                        if let subtitle {
                            Text(subtitle).font(.subheadline).foregroundStyle(SendoPalette.subdued)
                        }
                    }
                    content()
                }
                .frame(maxWidth: 520, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 4)
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
    var color = SendoPalette.subdued

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.heavy))
            .tracking(1.5)
            .foregroundStyle(color)
            .accessibilityLabel(text)
    }
}

struct SendoButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, link }

    private let kind: Kind

    init(_ kind: Kind) { self.kind = kind }

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if kind == .link {
                configuration.label
                    .font(.subheadline.weight(.bold))
                    .underline()
                    .foregroundStyle(SendoPalette.ink)
                    .padding(.horizontal, 3)
                    .frame(minHeight: 44)
            } else {
                SendoButtonLabel(label: configuration.label)
                    .foregroundStyle(kind == .primary ? SendoPalette.actionInk : SendoPalette.ink)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(kind == .primary ? SendoPalette.action : .clear, in: .rect(cornerRadius: 12))
                    .overlay {
                        if kind == .secondary {
                            RoundedRectangle(cornerRadius: 12).strokeBorder(SendoPalette.ink, lineWidth: 1.5)
                        }
                    }
            }
        }
        .contentShape(.rect)
        .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

private struct SendoButtonLabel<Label: View>: View {
    let label: Label
    @ScaledMetric(relativeTo: .headline) private var size = 21.0

    // textCase also uppercases the accessibility label, so the visible copy is hidden from
    // accessibility and an invisible original-case copy supplies the button's label.
    var body: some View {
        ZStack {
            label.textCase(.uppercase).accessibilityHidden(true)
            label.foregroundStyle(.clear)
        }
        .font(.system(size: size, weight: .heavy).width(.compressed))
        .tracking(0.8)
    }
}

struct SendoEmptyState: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(SendoPalette.ink)
                .frame(width: 48, height: 48)
                .background(SendoPalette.quiet, in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)
            SendoDisplayText(title, size: 28, weight: .heavy, relativeTo: .title2)
            Text(detail).foregroundStyle(SendoPalette.subdued)
        }
        .padding(.top, 8)
    }
}

struct SendoPanel: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(SendoPalette.panel, in: .rect(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(SendoPalette.line).allowsHitTesting(false) }
    }
}

/// The one high-contrast block each tab opens with. Pass a plate colour as `fill` when the block stands for a session.
struct SendoHero: ViewModifier {
    var fill = SendoPalette.hero
    var ink = SendoPalette.heroInk
    var outlined = false

    func body(content: Content) -> some View {
        content.frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .foregroundStyle(ink)
            .background(fill, in: .rect(cornerRadius: 20))
            .overlay {
                if outlined {
                    RoundedRectangle(cornerRadius: 20).strokeBorder(SendoPalette.plateOutline, lineWidth: 1.5)
                        .allowsHitTesting(false)
                }
            }
    }
}

struct SendoPlate: View {
    let number: Int
    let style: SendoSessionColor
    @ScaledMetric(relativeTo: .body) private var size = 36.0

    var body: some View {
        Text(number.formatted())
            .font(.system(size: size * 0.58, weight: .black).width(.compressed))
            .foregroundStyle(style.ink)
            .frame(width: size, height: size)
            .background(style.fill, in: .circle)
            .overlay { Circle().strokeBorder(SendoPalette.plateOutline, lineWidth: 1.5) }
            .accessibilityHidden(true)
    }
}

struct SendoField<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.footnote.weight(.semibold))
            content()
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .background(SendoPalette.panel, in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(SendoPalette.line).allowsHitTesting(false) }
        }
    }
}

/// A filter chip: condensed uppercase title, an optional count and star, solid when selected.
struct SendoChip: View {
    let title: String
    var count: Int? = nil
    var systemImage: String? = nil
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemImage { Image(systemName: systemImage).font(.caption.weight(.bold)) }
                SendoDisplayText(title, size: 19, weight: .heavy, relativeTo: .headline).tracking(0.6)
                if let count {
                    Text(count.formatted()).font(.footnote).foregroundStyle(selected ? SendoPalette.paper : SendoPalette.subdued)
                }
            }
            .foregroundStyle(selected ? SendoPalette.paper : SendoPalette.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(selected ? SendoPalette.ink : .clear, in: .rect(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? SendoPalette.ink : SendoPalette.line, lineWidth: 1.5) }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count.map { "\(title), \($0)" } ?? title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// A small read-only label such as a muscle or piece of equipment. Filled marks the primary one.
struct SendoTag: View {
    let text: String
    var filled = false

    var body: some View {
        SendoDisplayText(text, size: 18, weight: .heavy, relativeTo: .body)
            .tracking(0.5)
            .foregroundStyle(filled ? SendoPalette.paper : SendoPalette.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(filled ? SendoPalette.ink : .clear, in: .rect(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(filled ? SendoPalette.ink : SendoPalette.line, lineWidth: 1.5) }
    }
}

/// Lays children out in rows, wrapping to a new row when one is full.
struct SendoFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(in: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(in: bounds.width, subviews: subviews)
        for (subview, origin) in zip(subviews, arrangement.origins) {
            subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(in width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
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
