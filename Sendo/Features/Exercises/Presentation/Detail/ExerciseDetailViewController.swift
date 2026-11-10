//
//  ExerciseDetailView.swift
//  Sendo
//
//  Created by Aimar Ugarte on 8/5/22.
//

import UIKit

class ExerciseDetailViewController: SendoViewController {
    
    static func create(exercise: Exercise) -> ExerciseDetailViewController {
        return ExerciseDetailViewController(title: exercise.title)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
