//
//  AuthUser.swift
//  Sendo
//
//  Created by Aimar Ugarte on 4/6/22.
//

import Foundation

public struct AuthUser: Codable {

    let name: String
    let uid: String

    init(uid: String, name: String?) {
        self.uid = uid
        self.name = name ?? ""
    }
}
