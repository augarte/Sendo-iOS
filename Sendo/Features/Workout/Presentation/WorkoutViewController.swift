import SwiftUI

final class WorkoutViewController: BaseTabViewController {
    private let viewModel: WorkoutViewModel
    private let catalog: any ExerciseCatalog
    private var screen: UIHostingController<WorkoutHomeScreen>?
    private var loadError: Error?
    private var didOfferSetup = false

    init(viewModel: WorkoutViewModel, catalog: any ExerciseCatalog) {
        self.viewModel = viewModel
        self.catalog = catalog
        super.init(title: "Workout", image: "WorkoutWhite")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(SendoPalette.paper)
        loadWorkout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    func offerSetupIfNeeded() {
        loadViewIfNeeded()
        guard presentedViewController == nil, tabBarController?.presentedViewController == nil,
              !didOfferSetup, loadError == nil,
              viewModel.state?.shouldOfferSetup == true else { return }
        didOfferSetup = true
        showTrainingSetup()
    }

    private func loadWorkout() {
        do {
            try viewModel.load()
            loadError = nil
        } catch {
            loadError = error
        }
        render()
    }

    private func render() {
        let content = WorkoutHomeScreen(
            state: viewModel.state, failed: loadError != nil,
            onPlan: { [weak self] in self?.editPlan() },
            onSetup: { [weak self] in self?.showTrainingSetup() },
            onRetry: { [weak self] in
                self?.loadWorkout()
                self?.offerSetupIfNeeded()
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

    var trainingState: WorkoutTrainingState? { viewModel.state }

    func showTrainingSetup() {
        guard let state = viewModel.state, loadError == nil else { return }
        let isEditingPreferences = state.plan != nil
        let preferences = TrainingPreferences(
            weeklyDays: state.weeklyTrainingDays ?? 4, equipment: state.equipment ?? .gym
        )
        let setup = TrainingSetupViewController(
            preferences: preferences,
            isEditingPreferences: isEditingPreferences,
            onDefer: state.shouldOfferSetup ? { [weak self] in
                try self?.viewModel.deferSetup()
            } : nil
        ) { [weak self] preferences, navigation in
            guard let self else { return }
            if isEditingPreferences {
                try self.viewModel.saveTrainingPreferences(preferences)
                self.render()
                navigation.dismiss(animated: true)
            } else {
                let startingPlan = WorkoutStartingPlanViewController(preferences: preferences, catalog: self.catalog) { [weak self] plan in
                    guard let self else { return }
                    try self.viewModel.save(plan, preferences: preferences)
                    self.render()
                }
                navigation.pushViewController(startingPlan, animated: true)
            }
        }
        let navigation = UINavigationController(rootViewController: setup)
        navigation.overrideUserInterfaceStyle = Self.preferredInterfaceStyle
        navigation.modalPresentationStyle = .fullScreen
        navigation.isModalInPresentation = state.shouldOfferSetup
        let presenter: UIViewController = tabBarController ?? self
        presenter.present(navigation, animated: true)
    }

    private func editPlan() {
        guard let state = viewModel.state, loadError == nil else { return }
        let draft = state.plan ?? WorkoutPlan(name: "My workout plan", sessions: [])
        let editor = WorkoutPlanEditorViewController(plan: draft, catalog: catalog) { [weak self] plan in
            guard let self else { return }
            try self.viewModel.save(plan)
            self.render()
        }
        let navigation = UINavigationController(rootViewController: editor)
        navigation.overrideUserInterfaceStyle = Self.preferredInterfaceStyle
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true)
    }
}

private struct WorkoutHomeScreen: View {
    let state: WorkoutTrainingState?
    let failed: Bool
    let onPlan: () -> Void
    let onSetup: () -> Void
    let onRetry: () -> Void

    var body: some View {
        SendoPage(title: "Workout", context: "Training log") {
            if failed {
                empty(icon: "exclamationmark.circle", title: "Couldn’t load your workout plan",
                      detail: "Try opening your saved workout plan again.", action: "Retry", perform: onRetry)
            } else if let state, let plan = state.plan, let next = state.nextSession {
                let position = (plan.sessions.firstIndex { $0.id == next.id } ?? 0) + 1
                VStack(alignment: .leading, spacing: 6) {
                    SendoEyebrow(text: "Next session")
                    Text(next.name).font(.title3.weight(.semibold))
                    Text(summary(plan: plan, position: position, days: state.weeklyTrainingDays))
                        .font(.footnote).foregroundStyle(SendoPalette.subdued).monospacedDigit()
                        .accessibilityIdentifier("workout.nextSummary")
                }
                .modifier(SendoPanel())
                HStack {
                    Text("Your plan").font(.headline)
                    SwiftUI.Spacer()
                    Button("Edit plan", action: onPlan).buttonStyle(SendoButtonStyle(.link))
                }
                VStack(spacing: 0) {
                    ForEach(Array(plan.sessions.enumerated()), id: \.element.id) { index, session in
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(index + 1). \(session.name)")
                            SwiftUI.Spacer()
                            Text(WorkoutEditorRows.exerciseCount(session.exercises.count))
                                .foregroundStyle(SendoPalette.subdued).font(.footnote)
                        }
                        .padding(.vertical, 10)
                        Divider().overlay(SendoPalette.line)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("History").font(.headline)
                    if state.history.isEmpty {
                        Text("No completed workouts yet. Your first session will appear here.")
                            .font(.footnote).foregroundStyle(SendoPalette.subdued)
                    } else {
                        Text(state.history.count.formatted() + (state.history.count == 1 ? " completed workout" : " completed workouts"))
                            .font(.footnote).foregroundStyle(SendoPalette.subdued)
                    }
                }
                Button("Training preferences", action: onSetup).buttonStyle(SendoButtonStyle(.link))
            } else {
                empty(icon: "dumbbell", title: "No training plan yet",
                      detail: "Create a plan so your next session is ready to start.", action: "Create a plan", perform: onPlan)
                Button("Set up training", action: onSetup).buttonStyle(SendoButtonStyle(.link))
            }
        }
    }

    private func empty(icon: String, title: String, detail: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SendoEmptyState(icon: icon, title: title, detail: detail)
            Button(action, action: perform).buttonStyle(SendoButtonStyle(.primary))
        }
    }

    private func summary(plan: WorkoutPlan, position: Int, days: Int?) -> String {
        var details = [plan.name, "Session \(position) of \(plan.sessions.count)"]
        if let days { details.append(days == 1 ? "1 training day per week" : "\(days) training days per week") }
        return details.joined(separator: " · ")
    }
}
