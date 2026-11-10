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

    func save(_ plan: WorkoutPlan) throws {
        var updated = try state ?? repository.load()
        try updated.savePlan(plan)
        try repository.save(updated)
        state = updated
    }
}
