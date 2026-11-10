//
//  ExerciseViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation
import Combine

final class ExerciseListViewModel: ObservableObject {
    let exercises = CurrentValueSubject<[Exercise], Never>([])
    private let service: any ExerciseCatalog
    private var request: AnyCancellable?

    init(service: any ExerciseCatalog) {
        self.service = service
    }

    func fetchExercises() {
        request = service.fetchExerciseList()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion { print("Error: \(error.localizedDescription)") }
            } receiveValue: { [weak self] exercises in
                self?.exercises.send(exercises)
            }
    }
}
