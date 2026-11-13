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
                let nextIndex = plan.sessions.firstIndex { $0.id == next.id } ?? 0
                let nextStyle = SendoSessionColor(hex: next.colorHex, index: nextIndex)
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            SendoEyebrow(text: "Next session", color: nextStyle.ink)
                            SendoDisplayText(next.name, size: 54, relativeTo: .largeTitle)
                                .minimumScaleFactor(0.5)
                                .lineLimit(2)
                        }
                        SwiftUI.Spacer(minLength: 0)
                        nextBadge(number: nextIndex + 1, style: nextStyle)
                    }
                    Rectangle().fill(nextStyle.ink).frame(height: 1.5)
                    Text(summary(plan: plan, position: nextIndex + 1, days: state.weeklyTrainingDays))
                        .font(.footnote.weight(.semibold)).monospacedDigit()
                        .accessibilityIdentifier("workout.nextSummary")
                }
                .modifier(SendoHero(fill: nextStyle.fill, ink: nextStyle.ink, outlined: true))
                VStack(spacing: 0) {
                    HStack {
                        SendoDisplayText("Your plan", size: 26, weight: .heavy, relativeTo: .title3)
                            .accessibilityAddTraits(.isHeader)
                        SwiftUI.Spacer()
                        Button("Edit plan", action: onPlan).buttonStyle(SendoButtonStyle(.link))
                    }
                    ForEach(Array(plan.sessions.enumerated()), id: \.element.id) { index, session in
                        Divider().overlay(SendoPalette.line)
                        HStack(spacing: 14) {
                            SendoPlate(number: index + 1, style: SendoSessionColor(hex: session.colorHex, index: index))
                            Text(session.name).font(.body.weight(.semibold))
                            if session.id == next.id { nextTag(style: nextStyle) }
                            SwiftUI.Spacer(minLength: 8)
                            Text(WorkoutEditorRows.exerciseCount(session.exercises.count))
                                .foregroundStyle(SendoPalette.subdued).font(.subheadline)
                        }
                        .frame(minHeight: 58)
                        .accessibilityElement(children: .combine)
                    }
                    Divider().overlay(SendoPalette.line)
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("History").font(.headline)
                        Text(historyDetail(state.history.count))
                            .font(.subheadline).foregroundStyle(SendoPalette.subdued)
                    }
                    SwiftUI.Spacer(minLength: 0)
                    if !state.history.isEmpty {
                        SendoDisplayText(state.history.count.formatted(), size: 46, relativeTo: .title)
                    }
                }
                .modifier(SendoPanel())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("History, " + (state.history.isEmpty ? "" : state.history.count.formatted() + " ")
                                    + historyDetail(state.history.count))
                Button(action: onSetup) {
                    HStack {
                        Text("Training preferences").font(.subheadline.weight(.bold))
                        SwiftUI.Spacer()
                        Image(systemName: "chevron.right").font(.footnote.weight(.bold))
                    }
                    .padding(.horizontal, 4)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
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

    private func nextBadge(number: Int, style: SendoSessionColor) -> some View {
        Text(number.formatted())
            .font(.system(size: 38, weight: .black).width(.compressed))
            .foregroundStyle(style.fill)
            .frame(width: 60, height: 60)
            .overlay { Circle().strokeBorder(style.fill, lineWidth: 2) }
            .frame(width: 84, height: 84)
            .background(style.ink, in: .circle)
            .accessibilityHidden(true)
    }

    private func nextTag(style: SendoSessionColor) -> some View {
        Text("NEXT")
            .font(.caption2.weight(.heavy)).tracking(1)
            .foregroundStyle(style.ink)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(style.fill, in: .rect(cornerRadius: 4))
            .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(SendoPalette.plateOutline, lineWidth: 1.5) }
            .accessibilityLabel("Next")
    }

    private func historyDetail(_ count: Int) -> String {
        switch count {
        case 0: "No completed workouts yet. Your first session will appear here."
        case 1: "completed workout"
        default: "completed workouts"
        }
    }

    private func summary(plan: WorkoutPlan, position: Int, days: Int?) -> String {
        var details = [plan.name, "Session \(position) of \(plan.sessions.count)"]
        if let days { details.append(days == 1 ? "1 training day per week" : "\(days) training days per week") }
        return details.joined(separator: " · ")
    }
}
