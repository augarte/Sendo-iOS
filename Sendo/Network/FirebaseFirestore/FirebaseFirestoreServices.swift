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
    typealias UserCompletionStream = (CurrentValueSubject<AuthUser?, Never>)
    func createUser(authUser: AuthUser, completion: @escaping (Bool) -> ()) -> Void
    
    typealias MeasurementCompletionStream = (CurrentValueSubject<[Measurement], Never>)
    func fetchMeasurement(completion: MeasurementCompletionStream) -> Void
    func addMeasurementEntry(entry: Measurement, completion: @escaping (Bool) -> ()) -> Void
    func removeMeasurementEntry(entry: Measurement, completion: @escaping (Bool) -> ()) -> Void
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
    
    // MARK: - Auth
    public func createUser(authUser: AuthUser, completion: @escaping (Bool) -> ()) {
        let collection = Firestore.firestore().collection("users")
        let userData: [String: Any] = [
            "name": authUser.name,
        ]
        
        FirebaseFirestoreManager.shared.addDocumentDatabase(documentId: authUser.uid, data: userData, collection: collection).sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { success in
            completion(success)
        }.store(in: &cancellBag)
    }
    
    
    // MARK: - Measurements
    public func fetchMeasurement(completion: MeasurementCompletionStream) {
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
    
    public func addMeasurementEntry(entry: Measurement, completion: @escaping (Bool) -> ()) {
        let dataEntry: [String: Any] = [
            "value": entry.value,
        ]
        
        FirebaseFirestoreManager.shared.addToDatabase(data: dataEntry, collection: "measurements").sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { success in
            completion(success)
        }.store(in: &cancellBag)
    }
    
    public func modifyMeasurementEntry(entry: Measurement, hash: String, newValue: Any, completion: @escaping (Bool) -> ()) {
        FirebaseFirestoreManager.shared.modifyFromDatabase(document: entry.date, collection: "measurements", hash: hash, newValue: newValue).sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { success in
            completion(success)
        }.store(in: &cancellBag)
    }
    
    public func removeMeasurementEntry(entry: Measurement, completion: @escaping (Bool) -> ()) {
        FirebaseFirestoreManager.shared.removeFromDatabase(document: entry.date, collection: "measurements").sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { success in
            completion(success)
        }.store(in: &cancellBag)
    }
}
