//
//  ExerciseViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation
import Combine

class ExerciseListViewModel: ObservableObject {
    
    var exercises = CurrentValueSubject<[Exercise], Never>([Exercise]())
    
    init() {
        fetchExercises()
    }

}

extension ExerciseListViewModel {
    
    func fetchExercises() {
        FirebaseDatabaseServices.shared().fetchExerciseList(completion: self.exercises)
    }
}
