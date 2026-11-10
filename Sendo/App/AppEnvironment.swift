import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

enum AppEnvironment {
    static var usesFixtures: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--sendo-fixtures")
        #else
        false
        #endif
    }

    @MainActor
    static let session: FirebaseSessionStore? = {
        guard !usesFixtures else { return nil }
        return FirebaseSessionStore(
            auth: Auth.auth(),
            database: Firestore.firestore(),
            mergeDirectory: URL.applicationSupportDirectory.appendingPathComponent("GuestMeasurementMerges")
        )
    }()

    @MainActor
    static func progressViewModel() -> ProgressViewModel {
        #if DEBUG
        if usesFixtures { return ProgressViewModel(repository: FixtureMeasurements()) }
        #endif
        let viewModel = ProgressViewModel(repository: nil)
        if let session {
            viewModel.observeRepositories(
                session.$account
                    .map { $0?.uid }
                    .removeDuplicates()
                    .map { uid -> (any MeasurementRepository)? in
                        uid.map { FirestoreMeasurementRepository(database: Firestore.firestore(), userID: $0) }
                    }
                    .eraseToAnyPublisher()
            )
        }
        return viewModel
    }

    static func workouts() -> any WorkoutRepository {
        #if DEBUG
        if usesFixtures {
            if let value = ProcessInfo.processInfo.environment["SENDO_WORKOUT_STORE_ID"],
               let id = UUID(uuidString: value) {
                return LocalWorkoutRepository(fileURL: URL.temporaryDirectory
                    .appendingPathComponent("SendoWorkoutTests")
                    .appendingPathComponent(id.uuidString)
                    .appendingPathExtension("json"))
            }
            return FixtureWorkouts()
        }
        #endif
        return LocalWorkoutRepository(fileURL: URL.applicationSupportDirectory
            .appendingPathComponent("Sendo")
            .appendingPathComponent("Workouts.json"))
    }

    static func exercises() -> any ExerciseCatalog {
        #if DEBUG
        if usesFixtures { return FixtureExercises() }
        #endif
        return FirebaseDatabaseServices.shared()
    }
}

#if DEBUG
private final class FixtureMeasurements: MeasurementRepository {
    private var records: [MeasurementID: BodyMeasurement] = [:]

    func fetch() async throws -> [BodyMeasurement] { Array(records.values) }

    func create(_ measurement: BodyMeasurement) async throws { records[measurement.id] = measurement }
    func update(_ measurement: BodyMeasurement) async throws {
        guard records[measurement.id] != nil else { throw CocoaError(.fileNoSuchFile) }
        records[measurement.id] = measurement
    }
    func delete(id: MeasurementID) async throws { records[id] = nil }
}

private final class FixtureWorkouts: WorkoutRepository {
    private var state = WorkoutTrainingState()

    func load() throws -> WorkoutTrainingState { state }
    func save(_ state: WorkoutTrainingState) throws { self.state = state }
}

private struct FixtureExercises: ExerciseCatalog {
    func fetchExerciseList() -> AnyPublisher<[Exercise], Error> {
        Just([
            Exercise(
                id: "fixture-squat", name: "squat", title: "Bodyweight Squat", type: "strength",
                description: "Bend at the hips and knees.", steps: [], tips: [],
                primary: ["Quadriceps"], secondary: [], equipment: [], images: []
            ),
            Exercise(
                id: "fixture-lunge", name: "lunge", title: "Reverse Lunge", type: "strength",
                description: "Step back and bend both knees.", steps: [], tips: [],
                primary: ["Quadriceps"], secondary: [], equipment: [], images: []
            ),
            Exercise(
                id: "fixture-push-up", name: "push-up", title: "Push-Up", type: "strength",
                description: "Lower your chest and press back up.", steps: [], tips: [],
                primary: ["Chest"], secondary: [], equipment: [], images: []
            ),
            Exercise(
                id: "fixture-prone-y-raise", name: "prone-y-raise", title: "Prone Y Raise", type: "strength",
                description: "Lie face down and lift your arms.", steps: [], tips: [],
                primary: ["Upper Back"], secondary: [], equipment: [], images: []
            ),
            Exercise(
                id: "fixture-glute-bridge", name: "glute-bridge", title: "Glute Bridge", type: "strength",
                description: "Press through your feet to lift your hips.", steps: [], tips: [],
                primary: ["Glutes"], secondary: [], equipment: [], images: []
            )
        ]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
#endif
