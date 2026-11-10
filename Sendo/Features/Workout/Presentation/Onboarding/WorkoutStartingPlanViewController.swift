import Combine
import UIKit

final class WorkoutStartingPlanViewController: UITableViewController {
    private let preferences: TrainingPreferences
    private let catalog: any ExerciseCatalog
    private let onSave: (WorkoutPlan) throws -> Void
    private let sessionCountField = UITextField()
    private var templateRequest: AnyCancellable?
    private let templateRow = IndexPath(row: 0, section: 1)

    init(preferences: TrainingPreferences, catalog: any ExerciseCatalog, onSave: @escaping (WorkoutPlan) throws -> Void) {
        self.preferences = preferences
        self.catalog = catalog
        self.onSave = onSave
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Choose a starting plan"
        navigationItem.prompt = "2 of 3"
        sessionCountField.text = "5"
        sessionCountField.keyboardType = .numberPad
        sessionCountField.accessibilityIdentifier = "onboarding.sessionCount"
        tableView.keyboardDismissMode = .onDrag
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "\(preferences.weeklyDays) days per week · \(preferences.equipment.title)" : nil
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 0 ? "Choose a rotation length for the template. Your next session carries over into the next week." : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return WorkoutEditorRows.field("Sessions in the template", sessionCountField)
        }
        if indexPath == templateRow {
            return WorkoutEditorRows.action(templateRequest == nil ? "Use a template" : "Loading template…")
        }
        return WorkoutEditorRows.action("Build manually")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }
        view.endEditing(true)
        if indexPath == templateRow {
            loadTemplate()
        } else {
            finishRequest()
            openReview(WorkoutPlan(name: "My workout plan", sessions: []))
        }
    }

    private func loadTemplate() {
        guard templateRequest == nil else { return }
        guard let count = Int(sessionCountField.text ?? ""), StarterWorkoutTemplate.supportedSessionCounts.contains(count) else {
            showTemplateError(StarterWorkoutTemplate.TemplateError.invalidSessionCount.localizedDescription)
            return
        }

        templateRequest = catalog.fetchExerciseList()
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self, self.templateRequest != nil else { return }
                self.finishRequest()
                if case .failure = completion, self.navigationController?.topViewController === self {
                    self.showTemplateError("Couldn’t load exercises. Try again or build your plan manually.")
                }
            } receiveValue: { [weak self] exercises in
                guard let self, self.navigationController?.topViewController === self else { return }
                self.finishRequest()
                do {
                    let plan = try StarterWorkoutTemplate.makePlan(
                        sessionCount: count, equipment: self.preferences.equipment, catalog: exercises
                    )
                    self.openReview(plan)
                } catch {
                    self.showTemplateError(error.localizedDescription)
                }
            }
        tableView.reloadRows(at: [templateRow], with: .none)
    }

    private func finishRequest() {
        templateRequest = nil
        tableView.reloadRows(at: [templateRow], with: .none)
    }

    private func showTemplateError(_ message: String) {
        let alert = UIAlertController(title: "Template unavailable", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func openReview(_ plan: WorkoutPlan) {
        let editor = WorkoutPlanEditorViewController(plan: plan, catalog: catalog, onboardingPreferences: preferences, onSave: onSave)
        navigationController?.pushViewController(editor, animated: true)
    }
}
