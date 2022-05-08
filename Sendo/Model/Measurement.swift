//
//  Measurements.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import Foundation
import FirebaseFirestore

public struct Measurement: Codable {
    
    let value: Double
    
    init?(snapshot: QueryDocumentSnapshot) {
        guard let dic = snapshot.data() as? [String:Any] else {
            return nil
        }
        
//        guard let id = dic["id"] as? String else {
//            return nil
//        }
//        self.id = id
        
        if let value = dic["value"] as? Double {
            self.value = value
        } else {
            self.value = 0.0
        }
        
    }
}
