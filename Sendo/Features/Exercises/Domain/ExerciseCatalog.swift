import Combine
import Foundation

protocol ExerciseCatalog {
    func fetchExerciseList() -> AnyPublisher<[Exercise], Error>
}

enum ExerciseCatalogError: LocalizedError {
    case accessDenied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .accessDenied: "Your session can’t access the exercise catalog right now."
        case .unavailable: "The exercise catalog is unavailable. Check your connection and try again."
        }
    }

    static func message(for error: Error) -> String {
        (error as? Self ?? .unavailable).localizedDescription
    }
}
