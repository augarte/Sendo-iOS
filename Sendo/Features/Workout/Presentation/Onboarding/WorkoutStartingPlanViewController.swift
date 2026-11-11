import Combine
import SwiftUI

final class WorkoutStartingPlanViewController: SendoHostingController<StartingPlanScreen> {
    private let catalog: any ExerciseCatalog
    private let onSave: (WorkoutPlan) throws -> Void
    private let model: StartingPlanPresentation
    private var request: AnyCancellable?

    init(preferences: TrainingPreferences, catalog: any ExerciseCatalog, onSave: @escaping (WorkoutPlan) throws -> Void) {
        self.catalog = catalog
        self.onSave = onSave
        model = StartingPlanPresentation()
        super.init(rootView: StartingPlanScreen(preferences: preferences, model: model))
        rootView.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        rootView.onTemplate = { [weak self] in self?.loadTemplate() }
        rootView.onManual = { [weak self] in
            self?.openReview(WorkoutPlan(name: "My workout plan", sessions: []))
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func loadTemplate() {
        guard request == nil else { return }
        guard let count = Int(model.sessionCount), StarterWorkoutTemplate.supportedSessionCounts.contains(count) else {
            model.error = StarterWorkoutTemplate.TemplateError.invalidSessionCount.localizedDescription
            return
        }

        model.error = nil
        model.isLoading = true
        request = catalog.fetchExerciseList().first().receive(on: DispatchQueue.main).sink { [weak self] completion in
            self?.request = nil
            self?.model.isLoading = false
            if case .failure(let error) = completion {
                self?.model.error = ExerciseCatalogError.message(for: error)
            }
        } receiveValue: { [weak self] exercises in
            guard let self, self.navigationController?.topViewController === self else { return }
            do {
                let plan = try StarterWorkoutTemplate.makePlan(
                    sessionCount: count, equipment: self.rootView.preferences.equipment, catalog: exercises
                )
                self.openReview(plan)
            } catch {
                self.model.error = error.localizedDescription
            }
        }
    }

    private func openReview(_ plan: WorkoutPlan) {
        request = nil
        model.isLoading = false
        let editor = WorkoutPlanEditorViewController(plan: plan, catalog: catalog, onboardingPreferences: rootView.preferences, onSave: onSave)
        navigationController?.pushViewController(editor, animated: true)
    }
}

@MainActor
final class StartingPlanPresentation: ObservableObject {
    @Published var sessionCount = "5"
    @Published var isLoading = false
    @Published var error: String?
}

struct StartingPlanScreen: View {
    let preferences: TrainingPreferences
    @ObservedObject var model: StartingPlanPresentation
    var onBack: () -> Void = {}
    var onTemplate: () -> Void = {}
    var onManual: () -> Void = {}

    var body: some View {
        SendoPage(
            title: "Choose a starting plan", context: "2 of 3",
            subtitle: "\(preferences.weeklyDays) \(preferences.weeklyDays == 1 ? "day" : "days") per week · \(preferences.equipment.title)",
            back: ("Back", onBack)
        ) {
            VStack(alignment: .leading, spacing: 6) {
                SendoField(title: "Sessions in the rotation") {
                    TextField("5", text: $model.sessionCount)
                        .keyboardType(.numberPad)
                        .monospacedDigit()
                        .accessibilityLabel("Sessions in the rotation")
                        .accessibilityIdentifier("onboarding.sessionCount")
                }
                Text("Your next session carries over into the next week.")
                    .font(.footnote).foregroundStyle(SendoPalette.subdued)
            }
            VStack(alignment: .leading, spacing: 8) {
                SendoEyebrow(text: "Starter template")
                Text("Start with a template").font(.headline)
                Text("Review a rotation built from exercises for your equipment.")
                    .font(.footnote).foregroundStyle(SendoPalette.subdued)
                Button(model.isLoading ? "Loading template…" : "Use a template", action: onTemplate)
                    .buttonStyle(SendoButtonStyle(.primary))
                    .disabled(model.isLoading)
            }
            .modifier(SendoPanel())
            if let error = model.error { Text(error).font(.footnote).foregroundStyle(SendoPalette.error) }
            Button("Build manually", action: onManual).buttonStyle(SendoButtonStyle(.secondary))
        }
    }
}
