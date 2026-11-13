import Combine
import Foundation

protocol ExerciseCatalog {
    func fetchExerciseList() -> AnyPublisher<[Exercise], Error>
}

enum ExerciseCatalogError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable: "The exercise catalog couldn’t be loaded."
        }
    }

    static func message(for error: Error) -> String {
        (error as? Self ?? .unavailable).localizedDescription
    }
}
