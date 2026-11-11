import SwiftUI

final class WorkoutPlanEditorViewController: SendoHostingController<WorkoutPlanEditorScreen> {
    private let catalog: any ExerciseCatalog
    private let onSave: (WorkoutPlan) throws -> Void
    private let model: WorkoutPlanEditorPresentation

    init(
        plan: WorkoutPlan, catalog: any ExerciseCatalog, onboardingPreferences: TrainingPreferences? = nil,
        onSave: @escaping (WorkoutPlan) throws -> Void
    ) {
        self.catalog = catalog
        self.onSave = onSave
        model = WorkoutPlanEditorPresentation(draft: plan)
        super.init(rootView: WorkoutPlanEditorScreen(model: model, preferences: onboardingPreferences))
        rootView.onClose = { [weak self] in
            if onboardingPreferences == nil {
                self?.dismiss(animated: true)
            } else {
                self?.navigationController?.popViewController(animated: true)
            }
        }
        rootView.onOpen = { [weak self] session in self?.openSession(session) }
        rootView.onSave = { [weak self] in self?.save() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func save() {
        var plan = model.draft
        plan.name = plan.name.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try onSave(plan)
            dismiss(animated: true)
        } catch {
            model.error = error.localizedDescription
        }
    }

    private func openSession(_ session: PlannedSession?) {
        let session = session ?? PlannedSession(name: "Session \(model.draft.sessions.count + 1)", exercises: [])
        let editor = SessionEditorViewController(session: session, catalog: catalog) { [weak self] session in
            guard let self else { return }
            if let index = self.model.draft.sessions.firstIndex(where: { $0.id == session.id }) {
                self.model.draft.sessions[index] = session
            } else {
                self.model.draft.sessions.append(session)
            }
            self.model.error = nil
        }
        navigationController?.pushViewController(editor, animated: true)
    }
}

@MainActor
final class WorkoutPlanEditorPresentation: ObservableObject {
    @Published var draft: WorkoutPlan
    @Published var error: String?

    init(draft: WorkoutPlan) { self.draft = draft }
}

struct WorkoutPlanEditorScreen: View {
    @ObservedObject var model: WorkoutPlanEditorPresentation
    let preferences: TrainingPreferences?
    var onClose: () -> Void = {}
    var onOpen: (PlannedSession?) -> Void = { _ in }
    var onSave: () -> Void = {}

    var body: some View {
        SendoPage(
            title: preferences == nil ? "Workout plan" : "Review your plan",
            context: preferences == nil ? nil : "3 of 3",
            eyebrow: "Plan draft",
            subtitle: preferences.map { "\(model.draft.sessions.count) in rotation · \($0.weeklyDays) days per week · \($0.equipment.title)" },
            back: (preferences == nil ? "Cancel" : "Back", onClose)
        ) {
            if let preferences, !model.draft.sessions.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(0..<2) { week in
                            let offset = week * preferences.weeklyDays
                            let sessions = model.draft.sessions
                            let names = (offset..<(offset + preferences.weeklyDays)).map { sessions[$0 % sessions.count].name }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Week \(week + 1)").font(.footnote.weight(.semibold))
                                Text(names.joined(separator: " → ")).font(.footnote).foregroundStyle(SendoPalette.subdued)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, 10)
                } label: {
                    Text("How the rotation fits your week").font(.headline).foregroundStyle(SendoPalette.ink)
                }
                .disclosureGroupStyle(RotationPreviewStyle())
                .modifier(SendoPanel())
            }
            SendoField(title: "Plan name") {
                TextField("My workout plan", text: $model.draft.name)
                    .textInputAutocapitalization(.words)
                    .accessibilityLabel("Plan name")
                    .accessibilityIdentifier("workout.planName")
            }
            VStack(spacing: 0) {
                ForEach(Array(model.draft.sessions.enumerated()), id: \.element.id) { index, session in
                    HStack {
                        Button { onOpen(session) } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.name).font(.headline)
                                Text(WorkoutEditorRows.exerciseCount(session.exercises.count))
                                    .font(.footnote).foregroundStyle(SendoPalette.subdued)
                            }
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("workout.planEditor.session")
                        Menu {
                            Button("Move up", systemImage: "arrow.up") {
                                model.draft.sessions.swapAt(index, index - 1)
                            }
                            .disabled(index == 0)
                            Button("Move down", systemImage: "arrow.down") {
                                model.draft.sessions.swapAt(index, index + 1)
                            }
                            .disabled(index == model.draft.sessions.count - 1)
                            Button("Remove session", systemImage: "trash", role: .destructive) {
                                model.draft.sessions.removeAll { $0.id == session.id }
                            }
                        } label: {
                            Image(systemName: "ellipsis").frame(width: 44, height: 44).contentShape(.rect)
                        }
                        .accessibilityLabel("Actions for \(session.name)")
                    }
                    Divider().overlay(SendoPalette.line)
                }
            }
            Button("Add a session") { onOpen(nil) }.buttonStyle(SendoButtonStyle(.link))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if let error = model.error { Text(error).font(.footnote).foregroundStyle(SendoPalette.error) }
                Button(preferences == nil ? "Save plan" : "Save plan and finish", action: onSave)
                    .buttonStyle(SendoButtonStyle(.primary))
                    .accessibilityIdentifier(preferences == nil ? "workout.savePlan" : "onboarding.finish")
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(SendoPalette.paper)
            .overlay(alignment: .top) { Divider().overlay(SendoPalette.line) }
        }
    }
}

private struct RotationPreviewStyle: DisclosureGroupStyle {
    @State private var expanded = true

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                expanded.toggle()
            } label: {
                HStack {
                    configuration.label
                    SwiftUI.Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.footnote)
                }
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            if expanded { configuration.content }
        }
    }
}
