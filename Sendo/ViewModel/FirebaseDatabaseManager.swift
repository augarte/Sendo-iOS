//
//  FirebaseDatabaseManager.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation
import Combine
import FirebaseDatabase

final class FirebaseDatabaseManager: ObservableObject {
    
    let db = Database.database().reference()
    
    static var shared: FirebaseDatabaseManager = {
        let instance = FirebaseDatabaseManager()
        return instance
    }()
    
    private init() {}

    func fetchDatabase(child: String) -> AnyPublisher<DataSnapshot, Error> {
        Future { future in
            self.db.child(child).getData { error, snapshot in
                guard error == nil else {
                    return future(.failure(error!))
                }
                return future(.success(snapshot))
            }
        }.eraseToAnyPublisher()
    }

}

extension FirebaseDatabaseManager: NSCopying {

    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
}
