//
//  NewEntryLine.swift
//  Sendo
//
//  Created by Aimar Ugarte on 4/11/22.
//

import UIKit
import Combine

class NewEntryLine: UIView {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size05
    }
    
    private var currentNonce: String?
    private var cancellBag = Set<AnyCancellable>()
    
    private lazy var entryTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var entryField: UITextField = {
        let field = UITextField()
        field.textAlignment = .right
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyle()
    }
    
    func setup(title: String) {
        entryTitle.text = title
        applyStyle()
    }
    
    func applyStyle() {
        addSubview(entryTitle)
        addSubview(entryField)
        NSLayoutConstraint.activate([
            entryTitle.topAnchor.constraint(equalTo: topAnchor),
            entryTitle.bottomAnchor.constraint(equalTo: bottomAnchor),
            entryTitle.leadingAnchor.constraint(equalTo: leadingAnchor),
            entryTitle.trailingAnchor.constraint(equalTo: entryField.leadingAnchor, constant: Constants.margin),
            entryField.topAnchor.constraint(equalTo: topAnchor),
            entryField.bottomAnchor.constraint(equalTo: bottomAnchor),
            entryField.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}
