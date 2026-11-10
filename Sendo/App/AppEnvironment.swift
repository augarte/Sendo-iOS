import Combine
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
    static func measurements() -> any MeasurementRepository {
        #if DEBUG
        if usesFixtures { return FixtureMeasurements() }
        #endif
        return FirestoreMeasurementRepository(firestore: .shared)
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
