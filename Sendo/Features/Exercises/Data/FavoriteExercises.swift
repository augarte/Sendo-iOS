import Combine
import Foundation

/// The exercises the user starred, kept on this device.
@MainActor
final class FavoriteExercises: ObservableObject {
    static let shared = FavoriteExercises()

    @Published private(set) var ids: Set<ExerciseID>
    private let defaults: UserDefaults
    private let key = "favoriteExerciseIDs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ids = Set(defaults.stringArray(forKey: key) ?? [])
    }

    func contains(_ id: ExerciseID) -> Bool { ids.contains(id) }

    func toggle(_ id: ExerciseID) {
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        defaults.set(ids.sorted(), forKey: key)
    }
}
