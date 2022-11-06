//
//  ExerciseListTableViewCell.swift
//  Sendo
//
//  Created by Aimar Ugarte on 14/11/21.
//

import UIKit
import SDWebImage

class ExerciseListTableViewCell: UITableViewCell {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size03
        static let imageHeight: CGFloat = 56
        static let aspectRatio: CGFloat = 1.5
    }

    private lazy var picture: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "Placeholder")
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        return imageView
    }()

    private lazy var name: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadView()
        applyStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func loadView() {
        addSubview(picture)
        addSubview(name)
        NSLayoutConstraint.activate([
            picture.heightAnchor.constraint(equalToConstant: Constants.imageHeight),
            picture.widthAnchor.constraint(equalTo: picture.heightAnchor, multiplier: Constants.aspectRatio),
            picture.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.margin),
            picture.topAnchor.constraint(equalTo: topAnchor, constant: Constants.margin),
            bottomAnchor.constraint(equalTo: picture.bottomAnchor, constant: Constants.margin),
            name.leadingAnchor.constraint(equalTo: picture.trailingAnchor, constant: Constants.margin),
            name.topAnchor.constraint(equalTo: topAnchor, constant: Constants.margin),
            bottomAnchor.constraint(equalTo: name.bottomAnchor, constant: Constants.margin),
            trailingAnchor.constraint(equalTo: name.trailingAnchor, constant: Constants.margin),
        ])
    }
    
    private func applyStyle() {
        backgroundColor = .clear
        picture.layer.cornerRadius = Constants.imageHeight / 2
        picture.clipsToBounds = true
    }
}

extension ExerciseListTableViewCell {
    
    func configureCell(exercise: Exercise) {
        name.text = exercise.title
        
        if exercise.images.count == 0 {
            picture.image = UIImage(named: "Placeholder")
        } else if exercise.images.count == 1 {
            picture.sd_setImage(with: URL(string: exercise.images.first ?? ""), placeholderImage: UIImage(named: "Placeholder"))
        } else {
            picture.sd_setImage(with: URL(string: exercise.images[1]), placeholderImage: UIImage(named: "Placeholder"))
        }
    }
}
