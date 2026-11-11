import SwiftUI

final class ExercisePrescriptionViewController: SendoHostingController<ExercisePrescriptionScreen> {
    private let catalog: any ExerciseCatalog
    private let model: ExercisePrescriptionPresentation

    init(exercise: PlannedExercise, isNew: Bool, catalog: any ExerciseCatalog, onSave: @escaping (PlannedExercise) -> Void) {
        self.catalog = catalog
        model = ExercisePrescriptionPresentation(exercise: exercise)
        super.init(rootView: ExercisePrescriptionScreen(model: model, isNew: isNew, onSave: onSave))
        rootView.onCancel = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        rootView.onSwap = { [weak self] in self?.swapExercise() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func swapExercise() {
        let picker = ExercisePickerViewController(catalog: catalog, replacing: model.exercise.exerciseID) { [weak self] exercise in
            guard let self else { return }
            self.model.exercise.exerciseID = exercise.id
            self.model.exercise.title = exercise.title
            self.model.load = ""
            self.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(picker, animated: true)
    }
}

@MainActor
final class ExercisePrescriptionPresentation: ObservableObject {
    @Published var exercise: PlannedExercise
    @Published var sets: String
    @Published var minimum: String
    @Published var maximum: String
    @Published var load: String

    init(exercise: PlannedExercise) {
        self.exercise = exercise
        sets = String(exercise.sets)
        minimum = String(exercise.minimumReps)
        maximum = String(exercise.maximumReps)
        load = exercise.startingLoadKilograms?.formatted(.number.grouping(.never).precision(.fractionLength(0...16))) ?? ""
    }

    func prescription() throws -> PlannedExercise {
        guard let sets = Int(sets), let minimum = Int(minimum), let maximum = Int(maximum) else {
            throw WorkoutError.invalidPrescription
        }
        let text = load.trimmingCharacters(in: .whitespacesAndNewlines)
        var updated = exercise
        updated.sets = sets
        updated.minimumReps = minimum
        updated.maximumReps = maximum
        updated.startingLoadKilograms = try text.isEmpty ? nil : Double(text, format: .number.grouping(.never), lenient: false)
        try updated.validate()
        return updated
    }
}

struct ExercisePrescriptionScreen: View {
    @ObservedObject var model: ExercisePrescriptionPresentation
    let isNew: Bool
    let onSave: (PlannedExercise) -> Void
    var onCancel: () -> Void = {}
    var onSwap: () -> Void = {}
    @State private var showsError = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        SendoPage(title: isNew ? "Add exercise" : "Edit exercise", back: ("Cancel", onCancel)) {
            SendoField(title: "Exercise") {
                Button(action: onSwap) {
                    HStack {
                        Text(model.exercise.title).foregroundStyle(SendoPalette.ink)
                        SwiftUI.Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.caption)
                    }
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .accessibilityLabel("Swap exercise")
                .accessibilityValue(model.exercise.title)
            }
            Text("The picker suggests similar exercises that use compatible equipment.")
                .font(.footnote).foregroundStyle(SendoPalette.subdued)

            let columns = Array(repeating: GridItem(.flexible(), alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2)
            LazyVGrid(columns: columns, spacing: 10) {
                field("Sets", text: $model.sets)
                field("Starting load (kg)", text: $model.load, placeholder: "Optional", keyboard: .decimalPad)
                field("Minimum reps", text: $model.minimum)
                field("Maximum reps", text: $model.maximum)
            }
            if showsError {
                Text(WorkoutError.invalidPrescription.localizedDescription)
                    .font(.footnote).foregroundStyle(SendoPalette.error)
            }
            Button(isNew ? "Add exercise" : "Apply changes") {
                do { onSave(try model.prescription()) } catch { showsError = true }
            }
            .buttonStyle(SendoButtonStyle(.primary))
            .accessibilityIdentifier("workout.saveExercise")
        }
    }

    private func field(
        _ title: String, text: Binding<String>, placeholder: String = "", keyboard: UIKeyboardType = .numberPad
    ) -> some View {
        SendoField(title: title) {
            TextField(placeholder, text: text).keyboardType(keyboard).monospacedDigit().accessibilityLabel(title)
                .accessibilityIdentifier(keyboard == .decimalPad ? "workout.startingLoad" : title)
        }
    }
}
