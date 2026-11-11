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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
