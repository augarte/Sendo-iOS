import XCTest
#if DEBUG
@testable import Sendo_Dev
#else
@testable import Sendo
#endif

final class SendoTests: XCTestCase {
    func testExerciseRecordMapsLegacyCatalogFields() throws {
        let exercise = try XCTUnwrap(ExerciseRecord.decode([
            "id": "squat",
            "title": "Squat",
            "primer": "Bend at the hips and knees.",
            "png": ["https://example.com/squat.png"]
        ]))

        XCTAssertEqual(exercise.id, "squat")
        XCTAssertEqual(exercise.description, "Bend at the hips and knees.")
        XCTAssertEqual(exercise.images, ["https://example.com/squat.png"])
        XCTAssertEqual(exercise.equipment, [])
        XCTAssertNil(ExerciseRecord.decode(["title": "Missing ID"]))
    }

    func testLegacyMeasurementRetainsIDDateAndUnknownUnit() throws {
        let entry = try XCTUnwrap(MeasurementRecord.decode(id: "1700000000", fields: ["value": 72.5]))
        XCTAssertEqual(entry.id, "1700000000")
        XCTAssertEqual(entry.measuredAt, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(entry.kind, .weight)
        XCTAssertEqual(entry.value, 72.5)
        XCTAssertNil(entry.unit)
    }

    func testExplicitDateAndUnitRoundTripWithLegacyID() throws {
        let edited = BodyMeasurement(
            id: "1700000000",
            measuredAt: Date(timeIntervalSince1970: 1_600_000_000),
            kind: .weight,
            value: 158.5,
            unit: .pounds
        )
        XCTAssertEqual(MeasurementRecord.decode(id: edited.id, fields: MeasurementRecord.fields(for: edited)), edited)
    }

    @MainActor
    func testEditingDateAndValueUpdatesOneRecordByItsOriginalID() async throws {
        let original = try XCTUnwrap(MeasurementRecord.decode(id: "1700000000", fields: ["value": 72.5]))
        let repository = InMemoryMeasurementRepository(measurements: [original])
        let model = ProgressViewModel(repository: repository)
        await model.load()

        let edited = BodyMeasurement(
            id: original.id, measuredAt: original.measuredAt.addingTimeInterval(-86_400),
            kind: original.kind, value: 74, unit: original.unit
        )
        try await model.save(edited, isEditing: true, revision: model.revision)

        XCTAssertEqual(repository.updatedIDs, [original.id])
        XCTAssertEqual(repository.measurements, [edited])
        XCTAssertEqual(model.state.measurements, [edited])
    }

    @MainActor
    func testFailedEditPreservesOriginalAndCanBeRetried() async throws {
        let original = try XCTUnwrap(MeasurementRecord.decode(id: "1700000000", fields: ["value": 72.5]))
        let repository = InMemoryMeasurementRepository(measurements: [original])
        let model = ProgressViewModel(repository: repository)
        await model.load()
        let edited = BodyMeasurement(
            id: original.id, measuredAt: original.measuredAt, kind: original.kind, value: 75, unit: original.unit
        )
        repository.failUpdate = true

        do {
            try await model.save(edited, isEditing: true, revision: model.revision)
            XCTFail("Expected the update to fail")
        } catch InMemoryMeasurementRepository.Failure.rejectedUpdate {
            XCTAssertEqual(repository.measurements, [original])
            XCTAssertEqual(model.state.measurements, [original])
        }

        repository.failUpdate = false
        try await model.save(edited, isEditing: true, revision: model.revision)
        XCTAssertEqual(model.state.measurements, [edited])
    }

    @MainActor
    func testPreviousAccountResponseCannotReplaceNewAccountState() async {
        let old = InMemoryMeasurementRepository(measurements: [])
        let model = ProgressViewModel(repository: old)
        let date = Date()
        let oldEntry = BodyMeasurement(id: "old", measuredAt: date, kind: .weight, value: 71, unit: nil)
        let newEntry = BodyMeasurement(id: "new", measuredAt: date, kind: .weight, value: 72, unit: nil)
        let new = InMemoryMeasurementRepository(measurements: [newEntry])

        let oldLoad: Task<Void, Never> = await withCheckedContinuation { started in
            old.onFetch = { task in started.resume(returning: task) }
            old.fetchTask = Task { await model.load() }
        }
        model.replaceRepository(new)
        await model.load()
        old.finishFetch?([oldEntry])
        await oldLoad.value
        XCTAssertEqual(model.state.measurements, [newEntry])
    }

    @MainActor
    func testDraftFromPreviousAccountCannotWriteToNewAccount() async {
        let old = InMemoryMeasurementRepository(measurements: [])
        let new = InMemoryMeasurementRepository(measurements: [])
        let model = ProgressViewModel(repository: old)
        let revision = model.revision
        let draft = BodyMeasurement(id: "old-draft", measuredAt: Date(), kind: .weight, value: 70, unit: nil)

        model.replaceRepository(new)
        do {
            try await model.save(draft, isEditing: false, revision: revision)
            XCTFail("Expected the old draft to be rejected")
        } catch {
            XCTAssertTrue(new.measurements.isEmpty)
            XCTAssertTrue(model.state.measurements.isEmpty)
        }
    }

    func testMeasurementRejectsInvalidValues() {
        for value in [0.0, -1, .nan, .infinity] {
            let entry = BodyMeasurement(id: "draft", measuredAt: Date(), kind: .weight, value: value, unit: nil)
            XCTAssertThrowsError(try entry.validate())
        }
    }

    @MainActor
    func testMeasurementsWithTheSameDateRemainDistinct() async throws {
        let repository = InMemoryMeasurementRepository(measurements: [])
        let model = ProgressViewModel(repository: repository)
        let date = Date()
        let first = BodyMeasurement(id: "first", measuredAt: date, kind: .weight, value: 72, unit: nil)
        let second = BodyMeasurement(id: "second", measuredAt: date, kind: .weight, value: 73, unit: nil)

        try await model.save(first, isEditing: false, revision: model.revision)
        try await model.save(second, isEditing: false, revision: model.revision)

        XCTAssertEqual(repository.measurements, [first, second])
        XCTAssertEqual(model.state.measurements, [first, second])
    }
}

@MainActor
private final class InMemoryMeasurementRepository: MeasurementRepository {
    enum Failure: Error {
        case rejectedUpdate
    }

    private(set) var measurements: [BodyMeasurement]
    private(set) var updatedIDs: [MeasurementID] = []
    var failUpdate = false
    var onFetch: ((Task<Void, Never>) -> Void)?
    var fetchTask: Task<Void, Never>?
    var finishFetch: (([BodyMeasurement]) -> Void)?

    init(measurements: [BodyMeasurement]) {
        self.measurements = measurements
    }

    func fetch() async throws -> [BodyMeasurement] {
        guard let onFetch, let fetchTask else { return measurements }
        let entries: [BodyMeasurement] = await withCheckedContinuation { continuation in
            finishFetch = { continuation.resume(returning: $0) }
            onFetch(fetchTask)
        }
        return entries
    }

    func create(_ measurement: BodyMeasurement) async throws {
        measurements.append(measurement)
    }

    func update(_ measurement: BodyMeasurement) async throws {
        guard !failUpdate, let index = measurements.firstIndex(where: { $0.id == measurement.id }) else {
            throw Failure.rejectedUpdate
        }
        updatedIDs.append(measurement.id)
        measurements[index] = measurement
    }

    func delete(id: MeasurementID) async throws {
        measurements.removeAll { $0.id == id }
    }
}
