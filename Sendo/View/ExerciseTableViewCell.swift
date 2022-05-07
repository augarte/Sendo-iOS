//
//  ExerciseTableViewCell.swift
//  Sendo
//
//  Created by Aimar Ugarte on 14/11/21.
//

import UIKit
import SDWebImage

class ExerciseTableViewCell: UITableViewCell {
    
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyle()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func applyStyle() {
        picture.backgroundColor = UIColor.white
        picture.layer.cornerRadius = picture.frame.height / 2
        picture.clipsToBounds = true
    }
    
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
