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
}

class FirebaseFirestoreServices: FirebaseFirestoreServicesProtocol {
    
    private static var firebaseFirestoreService: FirebaseFirestoreServices = {
        FirebaseFirestoreServices()
    }()
    
    private var cancellBag = Set<AnyCancellable>()
    
    private init() { }
    
    class func shared() -> FirebaseFirestoreServices {
        firebaseFirestoreService
    }
}

extension FirebaseFirestoreServices {
    
    // MARK: - Auth
    func createUser(authUser: AuthUser, completion: @escaping (Bool) -> ()) {
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
}
