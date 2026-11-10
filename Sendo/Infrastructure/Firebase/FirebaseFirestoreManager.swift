//
//  FirebaseFirestoreManager.swift
//  Sendo
//
//  Created by Aimar Ugarte on 8/5/22.
//

import Foundation
import Combine
import FirebaseFirestore

final class FirebaseFirestoreManager: ObservableObject {

    let db = Firestore.firestore()
    var uid: String? = nil

    static var shared: FirebaseFirestoreManager = {
        return FirebaseFirestoreManager()
    }()

    private init() {
        uid = UserDefaults.standard.string(forKey: "firebaseUID") ?? nil
    }

    func addDocumentDatabase(documentId: String, data: [String : Any], collection: CollectionReference) -> AnyPublisher<Bool, Error> {
        Future { future in
            collection.document(documentId).setData(data) { err in
                if let err = err {
                    return future(.failure(err))
                } else {
                    return future(.success(true))
                }
            }
        }.eraseToAnyPublisher()
    }

    func userCollection(named name: String) throws -> CollectionReference {
        guard let uid else { throw FirestoreAccessError.missingUser }
        return db.collection("users").document(uid).collection(name)
    }

}

extension FirebaseFirestoreManager: NSCopying {

    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

}

private enum FirestoreAccessError: LocalizedError {
    case missingUser

    var errorDescription: String? { "Your account is unavailable. Please try again." }
}
