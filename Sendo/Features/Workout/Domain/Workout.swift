//
//  Workout.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/12/22.
//

import Foundation

public struct Workout: Codable {

    let userId: String
    let name: String
    let description: String
    let sessions: [Session]
    let image: String
}

public struct Session: Codable {

    let name: String
    let exercises: [Exercise]
}
