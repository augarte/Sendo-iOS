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
    private let authReady: AnyPublisher<Bool, Never>

    init(authReady: AnyPublisher<Bool, Never>) {
        self.authReady = authReady
    }

    func fetchExerciseList() -> AnyPublisher<[Exercise], Error> {
        authReady
            .filter { $0 }
            .first()
            .setFailureType(to: Error.self)
            .flatMap { _ in
                FirebaseDatabaseManager.shared.fetchDatabase(child: "exercises", orderedBy: "title")
            }
            .mapError { error -> Error in
                // Realtime Database reports a rules rejection as com.firebase code 1.
                let databaseError = error as NSError
                if databaseError.domain == "com.firebase", databaseError.code == 1 {
                    return ExerciseCatalogError.accessDenied
                }
                return error
            }
            .timeout(.seconds(20), scheduler: DispatchQueue.main, customError: { ExerciseCatalogError.unavailable })
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
