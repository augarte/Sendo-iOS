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
    
    private let service: any FirebaseDatabaseServicesProtocol

    init(service: any FirebaseDatabaseServicesProtocol) {
        self.service = service
        fetchExercises()
    }

}

extension ExerciseListViewModel {
    
    func fetchExercises() {
        service.fetchExerciseList(completion: self.exercises)
    }
}
