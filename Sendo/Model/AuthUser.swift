//
//  AuthUser.swift
//  Sendo
//
//  Created by Aimar Ugarte on 4/6/22.
//

import Foundation
import FirebaseFirestore

public struct AuthUser: Codable {
    
    let name: String
    let uid: String
    
    init?(snapshot: QueryDocumentSnapshot) {
        self.uid = snapshot.documentID
        
        let dic = snapshot.data()
        if let name = dic["name"] as? String {
            self.name = name
        } else {
            self.name = ""
        }
        
    }
    
    init(uid: String, name: String?) {
        self.uid = uid
        self.name = name ?? ""
    }
}
