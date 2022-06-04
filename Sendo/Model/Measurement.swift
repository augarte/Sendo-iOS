//
//  Measurements.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import Foundation
import FirebaseFirestore

public struct Measurement: Codable, Equatable {
    
    let date: String
    let value: Double
    
    init?(snapshot: QueryDocumentSnapshot) {
        guard let dic = snapshot.data() as? [String:Any] else {
            return nil
        }
        
        self.date = snapshot.documentID
        
        if let value = dic["value"] as? Double {
            self.value = value
        } else {
            self.value = 0.0
        }
        
    }
    
    init(date: String, value: Double) {
        self.date = date
        self.value = value
    }
}
