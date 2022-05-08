//
//  FirebaseFirestoreServices.swift
//  Sendo
//
//  Created by Aimar Ugarte on 8/5/22.
//

import Foundation
import Combine
import FirebaseFirestore

public protocol FirebaseFirestoreServicesProtocol {
    typealias CompletionStream = (CurrentValueSubject<[Measurement], Never>)
    
    func fetchMeasurement(completion: CompletionStream) -> Void
}

class FirebaseFirestoreServices: FirebaseFirestoreServicesProtocol {
    
    private static var firebaseFirestoreService: FirebaseFirestoreServices = {
        return FirebaseFirestoreServices()
    }()
    private var cancellBag = Set<AnyCancellable>()
    
    private init() {
    }
    
    class func shared() -> FirebaseFirestoreServices {
        return firebaseFirestoreService
    }
}

extension FirebaseFirestoreServices {
    
    public func fetchMeasurement(completion: CompletionStream) {
        FirebaseFirestoreManager.shared.fetchDatabase(collection: "measurements").sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { snapshot in
            completion.send(snapshot.documents.compactMap{
                Measurement(snapshot: $0)
            })
        }.store(in: &cancellBag)
    }
}
