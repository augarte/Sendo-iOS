//
//  Provider.swift
//  Sendo
//
//  Created by Aimar Ugarte on 16/9/23.
//

import Combine
import Foundation

public protocol ProgressProviderProtocol {
    typealias MeasurementCompletionStream = (CurrentValueSubject<[Measurement], Never>)
    func fetchMeasurement(completion: MeasurementCompletionStream) -> Void
    func addMeasurementEntry(entry: Measurement, completion: @escaping (Bool) -> ()) -> Void
    func modifyMeasurementEntry(entry: Measurement, hash: String, newValue: Any, completion: @escaping (Bool) -> ())
    func removeMeasurementEntry(entry: Measurement, completion: @escaping (Bool) -> ()) -> Void
}

class ProgressProvider: ProgressProviderProtocol {
    
    private enum Constants: String {
        case collection = "measurements"
    }
    
    private var cancellBag = Set<AnyCancellable>()
    
    // MARK: - Measurements
    func fetchMeasurement(completion: MeasurementCompletionStream) {
        FirebaseFirestoreManager.shared.fetchDatabase(collection: Constants.collection.rawValue).sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { snapshot in
            completion.send(snapshot.documents.compactMap{
                Measurement(snapshot: $0)
            }.sorted(by: { $0.date > $1.date }))
        }.store(in: &cancellBag)
    }
    
    func addMeasurementEntry(entry: Measurement, completion: @escaping (Bool) -> ()) {
        let dataEntry: [String: Any] = [
            "value": entry.value,
        ]
        
        FirebaseFirestoreManager.shared.addToDatabase(data: dataEntry, collection: Constants.collection.rawValue).sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { success in
            completion(success)
        }.store(in: &cancellBag)
    }
    
    func modifyMeasurementEntry(entry: Measurement, hash: String, newValue: Any, completion: @escaping (Bool) -> ()) {
        FirebaseFirestoreManager.shared.modifyFromDatabase(document: entry.date, collection: Constants.collection.rawValue, hash: hash, newValue: newValue).sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { success in
            completion(success)
        }.store(in: &cancellBag)
    }
    
    func removeMeasurementEntry(entry: Measurement, completion: @escaping (Bool) -> ()) {
        FirebaseFirestoreManager.shared.removeFromDatabase(document: entry.date, collection: Constants.collection.rawValue).sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { success in
            completion(success)
        }.store(in: &cancellBag)
    }
}
