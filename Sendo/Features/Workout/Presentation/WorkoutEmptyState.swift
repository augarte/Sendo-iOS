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
    
    private lazy var image: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "WorkoutEmptyState")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    func setupView() {
        addSubviews([image])
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: topAnchor),
            image.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.margin),
            trailingAnchor.constraint(equalTo: image.trailingAnchor, constant: Constants.margin),
            image.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
