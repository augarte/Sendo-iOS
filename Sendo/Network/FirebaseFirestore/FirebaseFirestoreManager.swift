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

    func fetchDatabase(collection: String) -> AnyPublisher<QuerySnapshot, Error> {
        Future { future in
            guard let uid = self.uid else {
                return future(.failure(NSError(domain:"", code:440, userInfo:nil)))
            }
            
            self.db.collection("users").document(uid).collection(collection).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    return future(.failure(err))
                } else if let querySnapshot = querySnapshot {
                    return future(.success(querySnapshot))
    //                    for document in querySnapshot!.documents {
    //                    }
                } else {
                    return future(.failure(NSError(domain:"", code:440, userInfo:nil)))
                }
            }
        }.eraseToAnyPublisher()
    }

}

extension FirebaseFirestoreManager: NSCopying {

    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
}