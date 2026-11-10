//
//  WorkoutViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/12/22.
//

import Foundation
import Combine

class WorkoutViewModel: ObservableObject {
    
    var workout = CurrentValueSubject<Workout?, Never>(nil)
    
    init() {
        fetchWorkout()
    }

}

extension WorkoutViewModel {
    
    func fetchWorkout() {
        //FirebaseDatabaseServices.shared().fetchExerciseList(completion: self.exercises)
    }
}
