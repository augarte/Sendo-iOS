import UIKit

final class SessionEditorViewController: UITableViewController {
    private let catalog: any ExerciseCatalog
    private let onSave: (PlannedSession) -> Void
    private var draft: PlannedSession
    private let nameField = UITextField()

    init(session: PlannedSession, catalog: any ExerciseCatalog, onSave: @escaping (PlannedSession) -> Void) {
        draft = session
        self.catalog = catalog
        self.onSave = onSave
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Session"
        nameField.text = draft.name
        nameField.placeholder = "Session name"
        nameField.accessibilityIdentifier = "workout.sessionName"
        nameField.autocapitalizationType = .words
        tableView.keyboardDismissMode = .onDrag
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        save.accessibilityIdentifier = "workout.saveSession"
        navigationItem.rightBarButtonItems = [save, editButtonItem]
    }

    @objc private func save() {
        draft.name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        do {
            try draft.validate()
            onSave(draft)
            navigationController?.popViewController(animated: true)
        } catch {
            WorkoutEditorRows.showError(error, on: self)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 1 ? draft.exercises.count : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 ? "Exercises" : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return WorkoutEditorRows.field("Session name", nameField)
        case 1:
            let exercise = draft.exercises[indexPath.row]
            let reps = exercise.minimumReps == exercise.maximumReps
                ? "\(exercise.minimumReps)"
                : "\(exercise.minimumReps)–\(exercise.maximumReps)"
            var details = "\(exercise.sets) × \(reps) reps"
            if let load = exercise.startingLoadKilograms { details += " · \(load.formatted()) kg" }
            return WorkoutEditorRows.detail(exercise.title, detail: details, accessory: true)
        default:
            return WorkoutEditorRows.action("Add exercise")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            openPrescription(draft.exercises[indexPath.row], isNew: false)
        } else if indexPath.section == 2 {
            let picker = ExercisePickerViewController(catalog: catalog) { [weak self] exercise in
                self?.openPrescription(PlannedExercise(
                    exerciseID: exercise.id, title: exercise.title, sets: 3, minimumReps: 8, maximumReps: 12
                ), isNew: true)
            }
            navigationController?.pushViewController(picker, animated: true)
        }
    }

    private func openPrescription(_ exercise: PlannedExercise, isNew: Bool) {
        let editor = ExercisePrescriptionViewController(exercise: exercise, isNew: isNew, catalog: catalog) { [weak self] exercise in
            guard let self else { return }
            if let index = self.draft.exercises.firstIndex(where: { $0.id == exercise.id }) {
                self.draft.exercises[index] = exercise
            } else {
                self.draft.exercises.append(exercise)
            }
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            self.navigationController?.popToViewController(self, animated: true)
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
        let exercise = draft.exercises.remove(at: source.row)
        draft.exercises.insert(exercise, at: destination.row)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        draft.exercises.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}
