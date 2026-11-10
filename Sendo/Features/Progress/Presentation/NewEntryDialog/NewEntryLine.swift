import UIKit

final class NewEntryLine: UIStackView {
    init(title: String, input: UIView) {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .center
        spacing = Spacer.size04
        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: Spacer.size02, leading: Spacer.size04, bottom: Spacer.size02, trailing: Spacer.size04
        )

        let label = UILabel()
        label.text = title
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        addArrangedSubview(label)
        addArrangedSubview(input)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
