import UIKit

final class WorkoutPlanEditorViewController: UITableViewController {
    private let catalog: any ExerciseCatalog
    private let onboardingPreferences: TrainingPreferences?
    private let previewSection = 3
    private let onSave: (WorkoutPlan) throws -> Void
    private var draft: WorkoutPlan
    private let nameField = UITextField()

    init(
        plan: WorkoutPlan, catalog: any ExerciseCatalog, onboardingPreferences: TrainingPreferences? = nil,
        onSave: @escaping (WorkoutPlan) throws -> Void
    ) {
        draft = plan
        self.catalog = catalog
        self.onboardingPreferences = onboardingPreferences
        self.onSave = onSave
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = onboardingPreferences == nil ? "Workout plan" : "Review your plan"
        navigationItem.prompt = onboardingPreferences == nil ? nil : "3 of 3"
        nameField.text = draft.name
        nameField.placeholder = "My workout plan"
        nameField.accessibilityIdentifier = "workout.planName"
        nameField.autocapitalizationType = .words
        tableView.keyboardDismissMode = .onDrag
        let saveButton: UIBarButtonItem
        if onboardingPreferences == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        } else {
            saveButton = UIBarButtonItem(title: "Finish", style: .done, target: self, action: #selector(save))
            saveButton.accessibilityLabel = "Save plan and finish"
            saveButton.accessibilityIdentifier = "onboarding.finish"
        }
        navigationItem.rightBarButtonItems = [saveButton, editButtonItem]
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func save() {
        draft.name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        do {
            try onSave(draft)
            dismiss(animated: true)
        } catch {
            WorkoutEditorRows.showError(error, on: self)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        onboardingPreferences == nil ? 3 : 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1: draft.sessions.count
        case previewSection: draft.sessions.isEmpty ? 0 : 2
        default: 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: "Session rotation"
        case previewSection where !draft.sessions.isEmpty: "How the rotation fits your week"
        default: nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 2 ? "Sessions repeat in this order at your own pace." : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return WorkoutEditorRows.field("Plan name", nameField)
        case 1:
            let session = draft.sessions[indexPath.row]
            let cell = WorkoutEditorRows.detail(
                session.name, detail: WorkoutEditorRows.exerciseCount(session.exercises.count), accessory: true
            )
            cell.accessibilityIdentifier = "workout.planEditor.session"
            return cell
        case previewSection:
            guard let preferences = onboardingPreferences, !draft.sessions.isEmpty else { return UITableViewCell() }
            let offset = indexPath.row * preferences.weeklyDays
            let names = (offset..<(offset + preferences.weeklyDays)).map { draft.sessions[$0 % draft.sessions.count].name }
            let cell = WorkoutEditorRows.detail("Week \(indexPath.row + 1)", detail: names.joined(separator: " → "))
            cell.selectionStyle = .none
            return cell
        default:
            return WorkoutEditorRows.action("Add session")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 || indexPath.section == 2 else { return }
        let session = indexPath.section == 1 ? draft.sessions[indexPath.row] : PlannedSession(
            name: "Session \(draft.sessions.count + 1)", exercises: []
        )
        let editor = SessionEditorViewController(session: session, catalog: catalog) { [weak self] session in
            guard let self else { return }
            if let index = self.draft.sessions.firstIndex(where: { $0.id == session.id }) {
                self.draft.sessions[index] = session
            } else {
                self.draft.sessions.append(session)
            }
            self.tableView.reloadSections(self.rotationSections, with: .automatic)
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 1
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 1
    }

    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt source: IndexPath, toProposedIndexPath proposed: IndexPath) -> IndexPath {
        proposed.section == source.section ? proposed : source
    }

    override func tableView(_ tableView: UITableView, moveRowAt source: IndexPath, to destination: IndexPath) {
        let session = draft.sessions.remove(at: source.row)
        draft.sessions.insert(session, at: destination.row)
        if onboardingPreferences != nil {
            tableView.reloadSections(IndexSet(integer: previewSection), with: .none)
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        draft.sessions.remove(at: indexPath.row)
        tableView.reloadSections(rotationSections, with: .automatic)
    }

    private var rotationSections: IndexSet {
        onboardingPreferences == nil ? IndexSet(integer: 1) : IndexSet([1, previewSection])
    }
}
