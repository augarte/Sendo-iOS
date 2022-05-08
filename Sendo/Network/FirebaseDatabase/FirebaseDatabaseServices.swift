//
//  SendoFirestore.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/5/22.
//

import Foundation
import Combine
import FirebaseDatabase

public protocol FirebaseDatabaseServicesProtocol {
    typealias CompletionStream = (CurrentValueSubject<[Exercise], Never>)
    
    func fetchExerciseList(completion: CompletionStream) -> Void
}

class FirebaseDatabaseServices: FirebaseDatabaseServicesProtocol {
    
    private static var firebaseDatabaseService: FirebaseDatabaseServices = {
        return FirebaseDatabaseServices()
    }()
    private var cancellBag = Set<AnyCancellable>()
    
    private init() {
    }
    
    class func shared() -> FirebaseDatabaseServices {
        return firebaseDatabaseService
    }
}

extension FirebaseDatabaseServices {
    
    public func fetchExerciseList(completion: CompletionStream) {
        FirebaseDatabaseManager.shared.fetchDatabase(child: "exercises", orderedBy: "title").sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { snapshot in
            completion.send(snapshot.children.compactMap{
                Exercise(snapshot: $0 as!DataSnapshot)
            })
        }.store(in: &cancellBag)
    }
}
