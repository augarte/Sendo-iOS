//
//  WorkoutEmptyState.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/12/22.
//

import UIKit

class WorkoutEmptyState: UIView {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size05
    }
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.text = "Empty State"
        return label
    }()
    
    func setupView() {
        backgroundColor = .blue
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
