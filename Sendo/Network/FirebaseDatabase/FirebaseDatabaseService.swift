//
//  SendoFirestore.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/5/22.
//

import Foundation
import FirebaseDatabase
import Combine

public protocol SendoFirestoreServiceProtocol {
    typealias CompletionStream = (CurrentValueSubject<[Exercise], Never>)
    
    func fetchExerciseList(completion: CompletionStream) -> Void
}

class SendoFirestoreService: SendoFirestoreServiceProtocol {
    
    private static var sendoFirestoreService: SendoFirestoreService = {
        let sendoFirestoreService = SendoFirestoreService()
        return sendoFirestoreService
    }()
    private var cancellBag = Set<AnyCancellable>()
    
    private init() {
    }
    
    class func shared() -> SendoFirestoreService {
        return sendoFirestoreService
    }
}

extension SendoFirestoreService {
    
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
