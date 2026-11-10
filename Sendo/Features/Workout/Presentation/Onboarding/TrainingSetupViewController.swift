import UIKit

final class TrainingSetupViewController: UITableViewController {
    private var preferences: TrainingPreferences
    private let onContinue: (TrainingPreferences, UINavigationController) throws -> Void
    private let onDefer: (() throws -> Void)?
    private let isEditingPreferences: Bool

    init(
        preferences: TrainingPreferences,
        isEditingPreferences: Bool,
        onDefer: (() throws -> Void)?,
        onContinue: @escaping (TrainingPreferences, UINavigationController) throws -> Void
    ) {
        self.preferences = preferences
        self.isEditingPreferences = isEditingPreferences
        self.onDefer = onDefer
        self.onContinue = onContinue
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = isEditingPreferences ? "Training preferences" : "Set up your training"
        navigationItem.prompt = isEditingPreferences ? nil : "1 of 3"
        if isEditingPreferences || onDefer == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel, target: self, action: #selector(cancel)
            )
        }
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1: TrainingEquipment.allCases.count
        case 2: onDefer == nil ? 1 : 2
        default: 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: "Training days per week"
        case 1: "Equipment"
        default: nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 0 ? "Choose how often you train. Your plan can have a different number of sessions." : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let days = UISegmentedControl(items: (1...7).map { String($0) })
            days.accessibilityLabel = "Training days per week"
            days.accessibilityIdentifier = "onboarding.trainingDays"
            days.selectedSegmentIndex = preferences.weeklyDays - 1
            days.addAction(UIAction { [weak self, weak days] _ in
                guard let days else { return }
                self?.preferences.weeklyDays = days.selectedSegmentIndex + 1
            }, for: .valueChanged)
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            days.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(days)
            let margins = cell.contentView.layoutMarginsGuide
            NSLayoutConstraint.activate([
                days.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                days.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                days.topAnchor.constraint(equalTo: margins.topAnchor),
                days.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
                days.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
            ])
            return cell
        case 1:
            let equipment = TrainingEquipment.allCases[indexPath.row]
            let cell = WorkoutEditorRows.detail(equipment.title)
            if equipment == preferences.equipment {
                cell.accessoryType = .checkmark
                cell.accessibilityTraits.insert(.selected)
            }
            return cell
        default:
            let next = isEditingPreferences ? "Save preferences" : "Continue"
            return WorkoutEditorRows.action(indexPath.row == 0 ? next : "Set up later")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 1:
            preferences.equipment = TrainingEquipment.allCases[indexPath.row]
            tableView.reloadSections(IndexSet(integer: 1), with: .none)
        case 2:
            do {
                if indexPath.row == 0 {
                    guard let navigationController else { return }
                    try onContinue(preferences, navigationController)
                } else {
                    try onDefer?()
                    dismiss(animated: true)
                }
            } catch {
                WorkoutEditorRows.showError(error, on: self)
            }
        default:
            break
        }
    }
}
