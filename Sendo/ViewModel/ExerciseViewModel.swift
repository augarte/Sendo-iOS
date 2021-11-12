//
//  ExerciseViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation
import FirebaseDatabase
import Combine

class ExerciseViewModel: ObservableObject {
    
    var exercises = CurrentValueSubject<[Exercise], Never>([Exercise]())
    private var cancellBag = Set<AnyCancellable>()
    
    init() {
        fetchExercises()
    }
    
    func fetchExercises() {
        FirebaseDatabaseManager.shared.fetchDatabase(child: "exercises").sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { snapshot in
            self.exercises.send(snapshot.children.compactMap{
                Exercise(snapshot: $0 as!DataSnapshot)
            })
        }.store(in: &cancellBag)
    }

}
