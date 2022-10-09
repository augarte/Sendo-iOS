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
    var value: Double
    
    init?(snapshot: QueryDocumentSnapshot) {
        self.date = snapshot.documentID
        
        let dic = snapshot.data()
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
