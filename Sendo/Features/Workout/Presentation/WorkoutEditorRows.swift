import UIKit

@MainActor
enum WorkoutEditorRows {
    static func field(_ label: String, _ field: UITextField) -> UITableViewCell {
        let title = UILabel()
        title.text = label
        title.font = .preferredFont(forTextStyle: .subheadline)
        title.adjustsFontForContentSizeCategory = true
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.accessibilityLabel = label

        let cell = UITableViewCell()
        cell.selectionStyle = .none
        let stack = UIStackView(arrangedSubviews: [title, field])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(stack)
        let margins = cell.contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            stack.topAnchor.constraint(equalTo: margins.topAnchor),
            stack.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        return cell
    }

    static func detail(_ title: String, detail: String? = nil, accessory: Bool = false) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = title
        content.secondaryText = detail
        cell.contentConfiguration = content
        cell.accessoryType = accessory ? .disclosureIndicator : .none
        return cell
    }

    static func action(_ title: String) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = title
        content.textProperties.color = cell.tintColor
        cell.contentConfiguration = content
        cell.accessibilityTraits.insert(.button)
        return cell
    }

    static func exerciseCount(_ count: Int) -> String {
        count == 1 ? "1 exercise" : "\(count) exercises"
    }

    static func showError(_ error: Error, on controller: UIViewController) {
        let alert = UIAlertController(title: "Couldn’t save changes", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        controller.present(alert, animated: true)
    }
}
