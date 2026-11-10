//
//  SendoFirestore.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/5/22.
//

import Foundation
import Combine
import FirebaseDatabase

final class FirebaseDatabaseServices: ExerciseCatalog {
    private static let instance = FirebaseDatabaseServices()

    private init() {}

    static func shared() -> FirebaseDatabaseServices { instance }

    func fetchExerciseList() -> AnyPublisher<[Exercise], Error> {
        FirebaseDatabaseManager.shared.fetchDatabase(child: "exercises", orderedBy: "title")
            .map { snapshot in
                snapshot.children.compactMap { child in
                    guard let child = child as? DataSnapshot else { return nil }
                    return ExerciseRecord.decode(child.value)
                }
            }
            .eraseToAnyPublisher()
    }
}

enum ExerciseRecord {
    static func decode(_ value: Any?) -> Exercise? {
        guard let fields = value as? [String: Any], let id = fields["id"] as? String else {
            return nil
        }

        return Exercise(
            id: id,
            name: fields["name"] as? String ?? "",
            title: fields["title"] as? String ?? "",
            type: fields["type"] as? String ?? "",
            description: fields["primer"] as? String ?? "",
            steps: fields["steps"] as? [String] ?? [],
            tips: fields["tips"] as? [String] ?? [],
            primary: fields["primary"] as? [String] ?? [],
            secondary: fields["secondary"] as? [String] ?? [],
            equipment: fields["equipment"] as? [String] ?? [],
            images: fields["png"] as? [String] ?? []
        )
    }
}
