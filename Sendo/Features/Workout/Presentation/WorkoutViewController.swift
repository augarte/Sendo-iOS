import UIKit

final class WorkoutViewController: BaseTabViewController, UITableViewDataSource {
    private let viewModel: WorkoutViewModel
    private let catalog: any ExerciseCatalog
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var loadError: Error?

    init(viewModel: WorkoutViewModel, catalog: any ExerciseCatalog) {
        self.viewModel = viewModel
        self.catalog = catalog
        super.init(title: "Workout", image: "WorkoutWhite")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        loadWorkout()
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
        let plan = viewModel.state?.plan
        let showsPlan = plan != nil && loadError == nil
        tableView.isHidden = !showsPlan
        navigationItem.rightBarButtonItem = showsPlan
            ? UIBarButtonItem(title: "Edit plan", style: .plain, target: self, action: #selector(editPlan))
            : nil

        if showsPlan {
            contentUnavailableConfiguration = nil
            tableView.reloadData()
            return
        }

        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: loadError == nil ? "list.bullet.rectangle" : "exclamationmark.circle")
        configuration.text = loadError == nil ? "No workout plan yet" : "Couldn’t load your workout plan"
        configuration.secondaryText = loadError == nil
            ? "Build a plan from the exercise library. Your sessions repeat in order as you train."
            : "Try opening your saved workout plan again."
        configuration.button = .filled()
        configuration.button.title = loadError == nil ? "Create a plan" : "Retry"
        configuration.buttonProperties.primaryAction = UIAction { [weak self] _ in
            guard let self else { return }
            if self.loadError == nil { self.editPlan() } else { self.loadWorkout() }
        }
        contentUnavailableConfiguration = configuration
    }

    @objc private func editPlan() {
        guard let state = viewModel.state, loadError == nil else { return }
        let draft = state.plan ?? WorkoutPlan(name: "My workout plan", sessions: [])
        let editor = WorkoutPlanEditorViewController(plan: draft, catalog: catalog) { [weak self] plan in
            guard let self else { return }
            try self.viewModel.save(plan)
            self.render()
        }
        present(UINavigationController(rootViewController: editor), animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : viewModel.state?.plan?.sessions.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Next session" : "Session rotation"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let state = viewModel.state, let plan = state.plan else { return UITableViewCell() }
        if indexPath.section == 0 {
            let nextSession = state.nextSession
            let position = plan.sessions.firstIndex { $0.id == nextSession?.id }.map { $0 + 1 } ?? 1
            var details = [plan.name, "Session \(position) of \(plan.sessions.count)"]
            if let days = state.weeklyTrainingDays { details.append("\(days) training days per week") }
            return WorkoutEditorRows.detail(nextSession?.name ?? plan.name, detail: details.joined(separator: " · "))
        }
        let session = plan.sessions[indexPath.row]
        return WorkoutEditorRows.detail(
            "\(indexPath.row + 1). \(session.name)", detail: WorkoutEditorRows.exerciseCount(session.exercises.count)
        )
    }
}
