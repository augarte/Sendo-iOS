import UIKit

final class NewEntryDialog: SendoViewController {
    private let measurement: BodyMeasurement?
    private let save: (BodyMeasurement) async throws -> Void
    private let entryID: MeasurementID
    private let decimalSeparator = Locale.current.decimalSeparator ?? "."
    private var isSaving = false

    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.date = measurement?.measuredAt ?? Date()
        picker.accessibilityLabel = "Date"
        return picker
    }()

    private lazy var valueField: UITextField = {
        let field = UITextField()
        field.keyboardType = .decimalPad
        field.textAlignment = .right
        field.placeholder = "90" + decimalSeparator + "0"
        field.accessibilityLabel = "Value"
        if let measurement {
            field.text = String(measurement.value).replacingOccurrences(of: ".", with: decimalSeparator)
        }
        return field
    }()

    init(measurement: BodyMeasurement? = nil, save: @escaping (BodyMeasurement) async throws -> Void) {
        self.measurement = measurement
        self.save = save
        self.entryID = measurement?.id ?? UUID().uuidString
        super.init(title: measurement == nil ? "New Entry" : "Edit Entry")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel", style: .plain, target: self, action: #selector(cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: measurement == nil ? "Add" : "Save", style: .done, target: self, action: #selector(saveEntry)
        )

        let form = UIStackView(arrangedSubviews: [
            NewEntryLine(title: "Date", input: datePicker),
            NewEntryLine(title: "Value", input: valueField)
        ])
        form.axis = .vertical
        form.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(form)
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacer.size05),
            form.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacer.size05),
            form.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacer.size05)
        ])
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func saveEntry() {
        guard !isSaving else { return }
        let text = (valueField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let value = Double(text.replacingOccurrences(of: decimalSeparator, with: ".")) ?? .nan
        let draft = BodyMeasurement(
            id: entryID,
            measuredAt: datePicker.date,
            kind: measurement?.kind ?? .weight,
            value: value,
            unit: measurement?.unit
        )

        setSaving(true)
        Task {
            do {
                try await save(draft)
                dismiss(animated: true)
            } catch {
                setSaving(false)
                let alert = UIAlertController(title: "Couldn’t save weight", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func setSaving(_ saving: Bool) {
        isSaving = saving
        isModalInPresentation = saving
        navigationController?.isModalInPresentation = saving
        navigationItem.leftBarButtonItem?.isEnabled = !saving
        navigationItem.rightBarButtonItem?.isEnabled = !saving
        datePicker.isEnabled = !saving
        valueField.isEnabled = !saving
    }
}
