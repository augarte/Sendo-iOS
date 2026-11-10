import UIKit

final class ExercisePrescriptionViewController: UITableViewController {
    private let catalog: any ExerciseCatalog
    private let isNew: Bool
    private let onSave: (PlannedExercise) -> Void
    private var draft: PlannedExercise
    private let setsField = UITextField()
    private let minimumRepsField = UITextField()
    private let maximumRepsField = UITextField()
    private let loadField = UITextField()

    init(exercise: PlannedExercise, isNew: Bool, catalog: any ExerciseCatalog, onSave: @escaping (PlannedExercise) -> Void) {
        draft = exercise
        self.isNew = isNew
        self.catalog = catalog
        self.onSave = onSave
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Exercise"
        setsField.text = String(draft.sets)
        minimumRepsField.text = String(draft.minimumReps)
        maximumRepsField.text = String(draft.maximumReps)
        for field in [setsField, minimumRepsField, maximumRepsField] { field.keyboardType = .numberPad }
        loadField.keyboardType = .decimalPad
        loadField.text = draft.startingLoadKilograms?.formatted(.number.grouping(.never).precision(.fractionLength(0...16)))
        loadField.placeholder = "Optional"
        loadField.accessibilityIdentifier = "workout.startingLoad"
        tableView.keyboardDismissMode = .onDrag
        let save = UIBarButtonItem(title: isNew ? "Add" : "Done", style: .done, target: self, action: #selector(save))
        save.accessibilityIdentifier = "workout.saveExercise"
        navigationItem.rightBarButtonItem = save
    }

    @objc private func save() {
        let loadText = loadField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        do {
            guard let sets = Int(setsField.text ?? ""), let minimum = Int(minimumRepsField.text ?? ""),
                  let maximum = Int(maximumRepsField.text ?? "") else {
                throw WorkoutError.invalidPrescription
            }
            let load = try loadText.isEmpty ? nil : Double(loadText, format: .number.grouping(.never), lenient: false)
            draft.sets = sets
            draft.minimumReps = minimum
            draft.maximumReps = maximum
            draft.startingLoadKilograms = load
            try draft.validate()
            onSave(draft)
        } catch {
            WorkoutEditorRows.showError(WorkoutError.invalidPrescription, on: self)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 2 : 4
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return indexPath.row == 0 ? WorkoutEditorRows.detail(draft.title) : WorkoutEditorRows.action("Swap exercise")
        }
        switch indexPath.row {
        case 0: return WorkoutEditorRows.field("Sets", setsField)
        case 1: return WorkoutEditorRows.field("Minimum reps", minimumRepsField)
        case 2: return WorkoutEditorRows.field("Maximum reps", maximumRepsField)
        default: return WorkoutEditorRows.field("Starting load (kg)", loadField)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0, indexPath.row == 1 else { return }
        let picker = ExercisePickerViewController(catalog: catalog, replacing: draft.exerciseID) { [weak self] exercise in
            guard let self else { return }
            self.draft.exerciseID = exercise.id
            self.draft.title = exercise.title
            self.loadField.text = nil
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            self.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(picker, animated: true)
    }
}
