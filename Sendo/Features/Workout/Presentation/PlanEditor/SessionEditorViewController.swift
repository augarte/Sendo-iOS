import SwiftUI

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor(SendoPalette.paper)
        tableView.separatorColor = UIColor(SendoPalette.line)
        view.tintColor = UIColor(SendoPalette.accent)
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
        switch section {
        case 0: 2
        case 1: draft.exercises.count
        default: 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 ? "Exercises" : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return indexPath.row == 0 ? WorkoutEditorRows.field("Session name", nameField) : colorRow()
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
        if indexPath.section == 0 {
            if indexPath.row == 1 { presentColorPicker() }
        } else if indexPath.section == 1 {
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

    private func colorRow() -> UITableViewCell {
        let hex = draft.colorHex.flatMap { $0.count == 6 ? UInt32($0, radix: 16) : nil }
        let name = hex.map { value in SendoPalette.suggestions.first { $0.hex == value }?.name ?? "Custom" } ?? "Automatic"
        let cell = WorkoutEditorRows.detail("Colour", detail: name, accessory: true)
        if var content = cell.contentConfiguration as? UIListContentConfiguration {
            if hex != nil {
                let fill = UIColor(SendoSessionColor(hex: draft.colorHex, index: 0).fill)
                content.image = UIImage(systemName: "circle.fill")?.withTintColor(fill, renderingMode: .alwaysOriginal)
            } else {
                content.image = UIImage(systemName: "circle.dashed")
                content.imageProperties.tintColor = UIColor(SendoPalette.subdued)
            }
            cell.contentConfiguration = content
        }
        cell.accessibilityIdentifier = "workout.sessionColor"
        return cell
    }

    private func presentColorPicker() {
        view.endEditing(true)
        let picker = SessionColorPicker(selection: draft.colorHex) { [weak self] hex in
            guard let self else { return }
            self.draft.colorHex = hex
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
        let host = UIHostingController(rootView: picker)
        if let sheet = host.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(host, animated: true)
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

struct SessionColorPicker: View {
    let onSelect: (String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selection: String?
    @State private var custom: Color

    init(selection: String?, onSelect: @escaping (String?) -> Void) {
        self.onSelect = onSelect
        _selection = State(initialValue: selection)
        _custom = State(initialValue: SendoSessionColor(hex: selection, index: 1).fill)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                SendoDisplayText("Session colour", size: 28, weight: .heavy, relativeTo: .title2)
                    .accessibilityAddTraits(.isHeader)
                SwiftUI.Spacer()
                Button("Done") { dismiss() }.buttonStyle(SendoButtonStyle(.link))
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
                swatch(name: "Automatic", hex: nil)
                ForEach(SendoPalette.suggestions, id: \.hex) { suggestion in
                    swatch(name: suggestion.name, hex: String(format: "%06X", suggestion.hex))
                }
            }
            ColorPicker("Custom colour", selection: customBinding, supportsOpacity: false)
                .font(.body.weight(.semibold))
                .frame(minHeight: 44)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundStyle(SendoPalette.ink)
        .background(SendoPalette.paper.ignoresSafeArea())
    }

    private var customBinding: Binding<Color> {
        Binding(
            get: { custom },
            set: { color in
                custom = color
                selection = SendoPalette.hexString(from: color)
                onSelect(selection)
            }
        )
    }

    private func swatch(name: String, hex: String?) -> some View {
        let selected = selection == hex
        return Button {
            selection = hex
            onSelect(hex)
            dismiss()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if hex == nil {
                        Circle().strokeBorder(SendoPalette.subdued, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    } else {
                        Circle().fill(SendoSessionColor(hex: hex, index: 0).fill)
                            .overlay { Circle().strokeBorder(SendoPalette.line, lineWidth: 1) }
                    }
                    if selected {
                        Circle().strokeBorder(SendoPalette.ink, lineWidth: 3).padding(-5)
                    }
                }
                .frame(width: 44, height: 44)
                .padding(5)
                Text(name).font(.caption).foregroundStyle(SendoPalette.subdued).lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
