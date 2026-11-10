import Foundation

enum StarterWorkoutTemplate {
    static let supportedSessionCounts = 1...30

    static func makePlan(sessionCount: Int, equipment: TrainingEquipment, catalog: [Exercise]) throws -> WorkoutPlan {
        guard supportedSessionCounts.contains(sessionCount) else { throw TemplateError.invalidSessionCount }

        let required = try Movement.allCases.map { movement in
            try resolve(movement, equipment: equipment, catalog: catalog)
        }
        let upper = Array(required.prefix(2))
        let lower = Array(required.suffix(2))
        func session(_ name: String, exercises: [Exercise]) -> PlannedSession {
            PlannedSession(name: name, exercises: exercises.map {
                PlannedExercise(exerciseID: $0.id, title: $0.title, sets: 3, minimumReps: 8, maximumReps: 12)
            })
        }
        let sessions: [PlannedSession]
        let name: String

        switch sessionCount {
        case 1...3:
            name = "Full Body"
            sessions = (1...sessionCount).map { index in
                session(sessionCount == 1 ? name : "\(name) \(index)", exercises: lower + upper)
            }
        case 5:
            name = "Upper, Lower, Push, Pull, Legs"
            sessions = [
                session("Upper", exercises: upper),
                session("Lower", exercises: lower),
                session("Push", exercises: [upper[0]]),
                session("Pull", exercises: [upper[1]]),
                session("Legs", exercises: lower)
            ]
        default:
            name = "Upper / Lower"
            sessions = (0..<sessionCount).map { index in
                let isUpper = index.isMultiple(of: 2)
                return session("\(isUpper ? "Upper" : "Lower") \(index / 2 + 1)", exercises: isUpper ? upper : lower)
            }
        }

        return WorkoutPlan(name: name, sessions: sessions)
    }

    private static func resolve(_ movement: Movement, equipment: TrainingEquipment, catalog: [Exercise]) throws -> Exercise {
        let available = catalog.filter { !$0.id.isEmpty && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        for name in movement.names(for: equipment) {
            let key = normalized(name)
            if let exercise = available.first(where: { normalized($0.title) == key || normalized($0.name) == key }) {
                return exercise
            }
        }
        throw TemplateError.missingExercises
    }

    private static func normalized(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private enum Movement: CaseIterable {
        case push, pull, squat, hinge

        func names(for equipment: TrainingEquipment) -> [String] {
            switch equipment {
            case .gym:
                namesAtGym + namesWithDumbbells + bodyweightNames
            case .dumbbells:
                namesWithDumbbells + bodyweightNames
            case .bodyweight:
                bodyweightNames
            }
        }

        private var namesAtGym: [String] {
            switch self {
            case .push: ["Barbell Bench Press", "Bench Press", "Machine Chest Press", "Chest Press"]
            case .pull: ["Lat Pulldown", "Cable Row", "Seated Cable Row", "Pull Up"]
            case .squat: ["Barbell Squat", "Back Squat", "Leg Press", "Barbell Back Squat"]
            case .hinge: ["Barbell Romanian Deadlift", "Romanian Deadlift", "Barbell Hip Thrust", "Hip Thrust"]
            }
        }

        private var namesWithDumbbells: [String] {
            switch self {
            case .push: ["Dumbbell Bench Press", "Dumbbell Floor Press", "Dumbbell Chest Press"]
            case .pull: ["Dumbbell Row", "One Arm Dumbbell Row", "Dumbbell Bent Over Row", "Bent Over Dumbbell Row"]
            case .squat: ["Dumbbell Goblet Squat", "Goblet Squat", "Dumbbell Squat", "Dumbbell Split Squat"]
            case .hinge: ["Dumbbell Romanian Deadlift", "Dumbbell Deadlift", "Dumbbell Glute Bridge"]
            }
        }

        private var bodyweightNames: [String] {
            switch self {
            case .push: ["Push Up", "Bodyweight Push Up", "Knee Push Up"]
            case .pull: ["Prone Y Raise", "Reverse Snow Angel", "Prone W Raise", "Superman Pull"]
            case .squat: ["Bodyweight Squat", "Air Squat", "Reverse Lunge"]
            case .hinge: ["Glute Bridge", "Bodyweight Glute Bridge", "Single Leg Glute Bridge", "Single Leg Hip Hinge"]
            }
        }
    }

    enum TemplateError: LocalizedError {
        case invalidSessionCount, missingExercises

        var errorDescription: String? {
            switch self {
            case .invalidSessionCount: "Enter between 1 and 30 sessions for the template."
            case .missingExercises: "The catalog is missing exercises for this equipment. Choose different equipment or build your plan manually."
            }
        }
    }
}
