import Foundation

struct WorkoutPlan: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var sessions: [PlannedSession]

    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WorkoutError.missingPlanName
        }
        guard !sessions.isEmpty, Set(sessions.map(\.id)).count == sessions.count else {
            throw WorkoutError.invalidSessions
        }
        for session in sessions {
            try session.validate()
        }
    }
}

struct PlannedSession: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var exercises: [PlannedExercise]

    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WorkoutError.missingSessionName
        }
        guard !exercises.isEmpty, Set(exercises.map(\.id)).count == exercises.count else {
            throw WorkoutError.invalidExercises
        }
        for exercise in exercises {
            try exercise.validate()
        }
    }
}

struct PlannedExercise: Codable, Equatable, Identifiable {
    var id = UUID()
    var exerciseID: ExerciseID
    var title: String
    var sets: Int
    var minimumReps: Int
    var maximumReps: Int
    var startingLoadKilograms: Double?

    func validate() throws {
        guard !exerciseID.isEmpty, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              sets > 0, minimumReps > 0, maximumReps >= minimumReps,
              validLoad(startingLoadKilograms) else {
            throw WorkoutError.invalidPrescription
        }
    }
}

struct WorkoutSet: Codable, Equatable, Identifiable {
    var id = UUID()
    let exerciseID: PlannedExercise.ID
    let reps: Int
    let loadKilograms: Double?
}

struct ActiveWorkout: Codable, Equatable, Identifiable {
    let id: UUID
    let planID: WorkoutPlan.ID
    let session: PlannedSession
    let startedAt: Date
    var sets: [WorkoutSet]
}

struct WorkoutLog: Codable, Equatable, Identifiable {
    let id: UUID
    let planID: WorkoutPlan.ID
    let session: PlannedSession
    let startedAt: Date
    let finishedAt: Date
    let sets: [WorkoutSet]
}

struct WorkoutTrainingState: Codable, Equatable {
    private(set) var weeklyTrainingDays: Int?
    private(set) var plan: WorkoutPlan?
    private(set) var nextSessionID: PlannedSession.ID?
    private(set) var activeWorkout: ActiveWorkout?
    private(set) var history: [WorkoutLog] = []

    var nextSession: PlannedSession? {
        guard let plan else { return nil }
        return plan.sessions.first { $0.id == nextSessionID } ?? plan.sessions.first
    }

    mutating func setWeeklyTrainingDays(_ days: Int) throws {
        guard (1...7).contains(days) else { throw WorkoutError.invalidTrainingDays }
        weeklyTrainingDays = days
    }

    mutating func savePlan(_ plan: WorkoutPlan) throws {
        try plan.validate()
        if self.plan?.id != plan.id || !plan.sessions.contains(where: { $0.id == nextSessionID }) {
            nextSessionID = plan.sessions.first?.id
        }
        self.plan = plan
    }

    mutating func startWorkout(at date: Date) throws {
        guard activeWorkout == nil else { return }
        guard let plan, let session = nextSession else { throw WorkoutError.missingPlan }
        activeWorkout = ActiveWorkout(id: UUID(), planID: plan.id, session: session, startedAt: date, sets: [])
    }

    mutating func record(_ set: WorkoutSet) throws {
        guard var workout = activeWorkout else { throw WorkoutError.missingActiveWorkout }
        guard set.reps > 0, validLoad(set.loadKilograms),
              workout.session.exercises.contains(where: { $0.id == set.exerciseID }) else {
            throw WorkoutError.invalidSet
        }
        guard !workout.sets.contains(where: { $0.id == set.id }) else { return }
        workout.sets.append(set)
        activeWorkout = workout
    }

    @discardableResult
    mutating func finishWorkout(at date: Date) throws -> WorkoutLog? {
        guard let workout = activeWorkout else { return nil }
        guard !workout.sets.isEmpty else {
            activeWorkout = nil
            return nil
        }
        guard date >= workout.startedAt else { throw WorkoutError.invalidFinishDate }

        let log = WorkoutLog(
            id: workout.id, planID: workout.planID, session: workout.session,
            startedAt: workout.startedAt, finishedAt: date, sets: workout.sets
        )
        history.append(log)
        activeWorkout = nil
        if let plan, plan.id == workout.planID,
           let index = plan.sessions.firstIndex(where: { $0.id == workout.session.id }) {
            nextSessionID = plan.sessions[(index + 1) % plan.sessions.count].id
        }
        return log
    }
}

private func validLoad(_ load: Double?) -> Bool {
    guard let load else { return true }
    return load.isFinite && load >= 0
}

enum WorkoutError: LocalizedError {
    case invalidTrainingDays, missingPlan, missingPlanName, invalidSessions, missingSessionName
    case invalidExercises, invalidPrescription, missingActiveWorkout, invalidSet, invalidFinishDate

    var errorDescription: String? {
        switch self {
        case .invalidTrainingDays: "Choose between one and seven training days per week."
        case .missingPlan: "Save a plan with at least one session first."
        case .missingPlanName: "Enter a name for the plan."
        case .invalidSessions: "Add at least one session to the plan."
        case .missingSessionName: "Enter a name for the session."
        case .invalidExercises: "Add at least one exercise to the session."
        case .invalidPrescription: "Enter positive sets and reps, a valid rep range, and an optional nonnegative load."
        case .missingActiveWorkout: "Start a workout before logging a set."
        case .invalidSet: "Enter positive reps and an optional nonnegative load for a workout exercise."
        case .invalidFinishDate: "The finish time must be at or after the start time."
        }
    }
}

protocol WorkoutRepository {
    func load() throws -> WorkoutTrainingState
    func save(_ state: WorkoutTrainingState) throws
}
