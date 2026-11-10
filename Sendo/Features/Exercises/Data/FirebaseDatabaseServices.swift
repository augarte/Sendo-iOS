//
//  SendoFirestore.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/5/22.
//

import Foundation
import Combine
import FirebaseDatabase

public protocol FirebaseDatabaseServicesProtocol {
    typealias CompletionStream = (CurrentValueSubject<[Exercise], Never>)
    
    func fetchExerciseList(completion: CompletionStream) -> Void
}

class FirebaseDatabaseServices: FirebaseDatabaseServicesProtocol {
    
    private static var firebaseDatabaseService: FirebaseDatabaseServices = {
        return FirebaseDatabaseServices()
    }()
    private var cancellBag = Set<AnyCancellable>()
    
    private init() {
    }
    
    class func shared() -> FirebaseDatabaseServices {
        return firebaseDatabaseService
    }
}

extension FirebaseDatabaseServices {
    
    public func fetchExerciseList(completion: CompletionStream) {
        FirebaseDatabaseManager.shared.fetchDatabase(child: "exercises", orderedBy: "title").sink { completion in
            switch completion {
            case .failure(let error): print("Error: \(error.localizedDescription)")
            case .finished: break
            }
        } receiveValue: { snapshot in
            completion.send(snapshot.children.compactMap { child in
                guard let child = child as? DataSnapshot else { return nil }
                return ExerciseRecord.decode(child.value)
            })
        }.store(in: &cancellBag)
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
