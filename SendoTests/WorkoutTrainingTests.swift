import XCTest

#if DEBUG
@testable import Sendo_Dev
#else
@testable import Sendo
#endif

final class WorkoutTrainingTests: XCTestCase {
    func testFiveSessionRotationResumesAtSessionFiveWithFourTrainingDays() throws {
        let fileURL = temporaryFile()
        let repository = LocalWorkoutRepository(fileURL: fileURL)
        var state = try repository.load()
        let plan = makePlan()
        try state.setWeeklyTrainingDays(4)
        try state.savePlan(plan)

        for session in plan.sessions.prefix(4) {
            XCTAssertEqual(state.nextSession?.id, session.id)
            try completeNextSession(in: &state)
        }
        try repository.save(state)

        let reopened = LocalWorkoutRepository(fileURL: fileURL)
        state = try reopened.load()
        XCTAssertEqual(state.weeklyTrainingDays, 4)
        XCTAssertEqual(state.plan?.sessions.count, 5)
        XCTAssertEqual(state.nextSession?.id, plan.sessions[4].id)
        XCTAssertEqual(state.history.count, 4)

        try state.setWeeklyTrainingDays(3)
        XCTAssertEqual(state.nextSession?.id, plan.sessions[4].id)
        try completeNextSession(in: &state)
        XCTAssertEqual(state.nextSession?.id, plan.sessions[0].id)
    }

    func testActiveWorkoutResumesAndRetainsOriginalSessionAfterEdit() throws {
        let fileURL = temporaryFile()
        let repository = LocalWorkoutRepository(fileURL: fileURL)
        var state = WorkoutTrainingState()
        var plan = makePlan()
        try state.savePlan(plan)
        let start = Date(timeIntervalSince1970: 100)
        try state.startWorkout(at: start)
        let original = try XCTUnwrap(state.activeWorkout)
        let exercise = try XCTUnwrap(original.session.exercises.first)
        let set = WorkoutSet(exerciseID: exercise.id, reps: 8, loadKilograms: 30)
        try state.record(set)
        try repository.save(state)

        state = try LocalWorkoutRepository(fileURL: fileURL).load()
        try state.startWorkout(at: start.addingTimeInterval(60))
        try state.record(set)
        plan.sessions[0].name = "Renamed"
        plan.sessions.swapAt(1, 2)
        try state.savePlan(plan)
        XCTAssertEqual(state.nextSession?.id, original.session.id)

        let finished = try XCTUnwrap(state.finishWorkout(at: start.addingTimeInterval(120)))
        XCTAssertEqual(finished.id, original.id)
        XCTAssertEqual(finished.session, original.session)
        XCTAssertEqual(finished.sets, [set])
        XCTAssertEqual(state.nextSession?.id, plan.sessions[1].id)
        XCTAssertNil(try state.finishWorkout(at: start.addingTimeInterval(120)))
        XCTAssertEqual(state.history.count, 1)
    }

    func testEndingEmptyWorkoutPreservesRotation() throws {
        var state = WorkoutTrainingState()
        try state.savePlan(makePlan())
        let initial = state.nextSession?.id
        let start = Date()
        try state.startWorkout(at: start)
        XCTAssertNil(try state.finishWorkout(at: start))
        XCTAssertNil(state.activeWorkout)
        XCTAssertEqual(state.nextSession?.id, initial)
        XCTAssertTrue(state.history.isEmpty)
    }

    func testInvalidDraftCannotReplaceSavedPlan() throws {
        var state = WorkoutTrainingState()
        let plan = makePlan()
        try state.savePlan(plan)
        var invalid = plan
        invalid.sessions[0].exercises[0].maximumReps = 0
        XCTAssertThrowsError(try state.savePlan(invalid))
        XCTAssertEqual(state.plan, plan)
        XCTAssertThrowsError(try state.setWeeklyTrainingDays(8))
    }

    func testUnreadableWorkoutDataIsReported() throws {
        let fileURL = temporaryFile()
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("invalid data".utf8).write(to: fileURL)
        XCTAssertThrowsError(try LocalWorkoutRepository(fileURL: fileURL).load())
    }

    private func completeNextSession(in state: inout WorkoutTrainingState) throws {
        let start = Date()
        try state.startWorkout(at: start)
        let exercise = try XCTUnwrap(state.activeWorkout?.session.exercises.first)
        try state.record(WorkoutSet(exerciseID: exercise.id, reps: 8, loadKilograms: nil))
        _ = try state.finishWorkout(at: start.addingTimeInterval(60))
    }

    private func makePlan() -> WorkoutPlan {
        WorkoutPlan(name: "Training rotation", sessions: (1...5).map { index in
            PlannedSession(name: "Session \(index)", exercises: [
                PlannedExercise(
                    exerciseID: "squat", title: "Squat", sets: 3,
                    minimumReps: 8, maximumReps: 10, startingLoadKilograms: nil
                )
            ])
        })
    }

    private func temporaryFile() -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
        return folder.appendingPathComponent("workouts.json")
    }
}
