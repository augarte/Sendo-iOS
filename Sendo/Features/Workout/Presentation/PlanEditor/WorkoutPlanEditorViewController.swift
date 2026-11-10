import UIKit

final class WorkoutPlanEditorViewController: UITableViewController {
    private let catalog: any ExerciseCatalog
    private let onSave: (WorkoutPlan) throws -> Void
    private var draft: WorkoutPlan
    private let nameField = UITextField()

    init(plan: WorkoutPlan, catalog: any ExerciseCatalog, onSave: @escaping (WorkoutPlan) throws -> Void) {
        draft = plan
        self.catalog = catalog
        self.onSave = onSave
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Workout plan"
        nameField.text = draft.name
        nameField.placeholder = "My workout plan"
        nameField.accessibilityIdentifier = "workout.planName"
        nameField.autocapitalizationType = .words
        tableView.keyboardDismissMode = .onDrag
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save)),
            editButtonItem
        ]
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

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 1 ? draft.sessions.count : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 ? "Session rotation" : nil
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
        default:
            return WorkoutEditorRows.action("Add session")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section != 0 else { return }
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
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
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
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        draft.sessions.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}
