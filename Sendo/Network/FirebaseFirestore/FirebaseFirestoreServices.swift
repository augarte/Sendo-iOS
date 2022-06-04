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
    
    // MARK: - Measurements
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
    
    public func addMeasurementEntry(entry: Measurement, completion: CompletionStream) {
        let dataEntry: [String: Any] = [
            "value": entry.value,
        ]
        
        FirebaseFirestoreManager.shared.addToDatabase(data: dataEntry, collection: "measurements").sink { completion in
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
    
    public func removeMeasurementEntry(entry: Measurement, completion: CompletionStream) {
        FirebaseFirestoreManager.shared.removeFromDatabase(document: entry.date, collection: "measurements").sink { completion in
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
