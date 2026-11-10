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

    func fetchDatabase(child: String, orderedBy: String?) -> AnyPublisher<DataSnapshot, Error> {
        Future { future in
            let childRef = self.db.child(child)
            var queryRef = childRef.queryOrderedByKey()
            if let orderValue = orderedBy, !orderValue.isEmpty {
                queryRef = childRef.queryOrdered(byChild: orderValue)
            }
            queryRef.observeSingleEvent(of: .value, with: { snapshot in
                return future(.success(snapshot))
            }) { (error) in
                return future(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

}

extension FirebaseDatabaseManager: NSCopying {

    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
}
