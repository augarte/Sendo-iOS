import SwiftUI

final class TrainingSetupViewController: SendoHostingController<TrainingSetupScreen> {
    init(
        preferences: TrainingPreferences,
        isEditingPreferences: Bool,
        onDefer: (() throws -> Void)?,
        onContinue: @escaping (TrainingPreferences, UINavigationController) throws -> Void
    ) {
        super.init(rootView: TrainingSetupScreen(preferences: preferences, isEditing: isEditingPreferences))
        rootView.onContinue = { [weak self] preferences in
            guard let navigation = self?.navigationController else { return }
            try onContinue(preferences, navigation)
        }
        if let onDefer {
            rootView.onDefer = { [weak self] in
                try onDefer()
                self?.dismiss(animated: true)
            }
        } else {
            rootView.onCancel = { [weak self] in self?.dismiss(animated: true) }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

struct TrainingSetupScreen: View {
    @State var preferences: TrainingPreferences
    let isEditing: Bool
    var onContinue: (TrainingPreferences) throws -> Void = { _ in }
    var onDefer: (() throws -> Void)?
    var onCancel: (() -> Void)?
    @State private var error: String?
    @Environment(\.dynamicTypeSize) private var typeSize

    init(preferences: TrainingPreferences, isEditing: Bool) {
        _preferences = State(initialValue: preferences)
        self.isEditing = isEditing
    }

    var body: some View {
        SendoPage(
            title: isEditing ? "Training preferences" : "Set up your training",
            context: isEditing ? nil : "1 of 3",
            subtitle: "Choose how often you go to the gym and what equipment you use.",
            back: isEditing ? onCancel.map { ("Cancel", $0) } : nil
        ) {
            SendoField(title: "Training days per week") {
                Menu {
                    ForEach(1...7, id: \.self) { day in
                        Button(dayTitle(day)) { preferences.weeklyDays = day }
                    }
                } label: {
                    HStack {
                        Text(dayTitle(preferences.weeklyDays)).foregroundStyle(SendoPalette.ink)
                        SwiftUI.Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.caption)
                    }
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .accessibilityIdentifier("onboarding.trainingDays")
                .accessibilityLabel("Training days per week")
                .accessibilityValue(dayTitle(preferences.weeklyDays))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Equipment").font(.footnote.weight(.semibold))
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
                    : AnyLayout(HStackLayout(spacing: 6))
                layout {
                    ForEach(TrainingEquipment.allCases, id: \.self) { equipment in
                        let selected = equipment == preferences.equipment
                        Button {
                            preferences.equipment = equipment
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                                    .accessibilityHidden(true)
                                Text(equipment.title)
                            }
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 8)
                            .frame(minHeight: 44)
                            .foregroundStyle(selected ? SendoPalette.accent : SendoPalette.ink)
                            .background(selected ? SendoPalette.quiet : .clear, in: .rect(cornerRadius: 8))
                            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? SendoPalette.accent : SendoPalette.line) }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
            if let error { Text(error).foregroundStyle(SendoPalette.error).font(.footnote) }
            Button(isEditing ? "Save preferences" : "Continue") { perform { try onContinue(preferences) } }
                .buttonStyle(SendoButtonStyle(.primary))
            if let onDefer {
                Button("Set up later") { perform(onDefer) }.buttonStyle(SendoButtonStyle(.link))
            } else if !isEditing, let onCancel {
                Button("Cancel", action: onCancel).buttonStyle(SendoButtonStyle(.link))
            }
        }
    }

    private func dayTitle(_ day: Int) -> String { day == 1 ? "1 day" : "\(day) days" }

    private func perform(_ action: () throws -> Void) {
        do { try action() } catch { self.error = error.localizedDescription }
    }
}
