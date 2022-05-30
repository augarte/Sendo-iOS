//
//  ExerciseDetailView.swift
//  Sendo
//
//  Created by Aimar Ugarte on 8/5/22.
//

import UIKit

class ExerciseDetailView: SendoViewController {
    
    static func create(exercise: Exercise) -> ExerciseDetailView {
        return ExerciseDetailView(title: exercise.title, nibName: ExerciseDetailView.typeName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
