import Foundation

struct LocalWorkoutRepository: WorkoutRepository {
    let fileURL: URL

    func load() throws -> WorkoutTrainingState {
        do {
            return try JSONDecoder().decode(WorkoutTrainingState.self, from: Data(contentsOf: fileURL))
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return WorkoutTrainingState()
        }
    }

    func save(_ state: WorkoutTrainingState) throws {
        let data = try JSONEncoder().encode(state)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
