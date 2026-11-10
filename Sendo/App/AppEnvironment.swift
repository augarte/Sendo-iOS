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

    static func exercises() -> any FirebaseDatabaseServicesProtocol {
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

private struct FixtureExercises: FirebaseDatabaseServicesProtocol {
    func fetchExerciseList(completion: CompletionStream) {
        completion.send([
            Exercise(
                id: "fixture-squat", name: "squat", title: "Bodyweight Squat", type: "strength",
                description: "Bend at the hips and knees.", steps: [], tips: [],
                primary: ["Quadriceps"], secondary: [], equipment: [], images: []
            )
        ])
    }
}
#endif
