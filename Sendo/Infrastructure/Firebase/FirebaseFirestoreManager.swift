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

    static var shared: FirebaseFirestoreManager = {
        return FirebaseFirestoreManager()
    }()

    private init() {}

    func addDocumentDatabase(documentId: String, data: [String : Any], collection: CollectionReference) -> AnyPublisher<Bool, Error> {
        Future { future in
            collection.document(documentId).setData(data, merge: true) { err in
                if let err = err {
                    return future(.failure(err))
                } else {
                    return future(.success(true))
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
