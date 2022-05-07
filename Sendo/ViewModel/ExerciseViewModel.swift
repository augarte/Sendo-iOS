//
//  ExerciseViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation
import Combine

class ExerciseViewModel: ObservableObject {
    
    var exercises = CurrentValueSubject<[Exercise], Never>([Exercise]())
    
    init() {
        fetchExercises()
    }

}

extension ExerciseViewModel {
    
    func fetchExercises() {
        SendoFirestoreService.shared().fetchExerciseList(completion: self.exercises)
    }
}
