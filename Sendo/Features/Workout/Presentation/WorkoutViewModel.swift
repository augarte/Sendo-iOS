@MainActor
final class WorkoutViewModel {
    private let repository: any WorkoutRepository
    private(set) var state: WorkoutTrainingState?

    init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    func load() throws {
        state = try repository.load()
    }

    func save(_ plan: WorkoutPlan, preferences: TrainingPreferences? = nil) throws {
        var updated = try state ?? repository.load()
        try updated.savePlan(plan)
        if let preferences { try updated.saveTrainingPreferences(preferences) }
        try persist(updated)
    }

    func saveTrainingPreferences(_ preferences: TrainingPreferences) throws {
        var updated = try state ?? repository.load()
        try updated.saveTrainingPreferences(preferences)
        try persist(updated)
    }

    func deferSetup() throws {
        var updated = try state ?? repository.load()
        updated.deferSetup()
        try persist(updated)
    }

    private func persist(_ updated: WorkoutTrainingState) throws {
        try repository.save(updated)
        state = updated
    }
}
