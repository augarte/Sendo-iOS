//
//  Exercise.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation

typealias ExerciseID = String

public struct Exercise: Codable {

    let id: ExerciseID
    let name: String
    let title: String
    let type: String
    let description: String
    let steps: [String]
    let tips: [String]
    let primary: [String]
    let secondary: [String]
    let equipment: [String]
    let images: [String]
}
