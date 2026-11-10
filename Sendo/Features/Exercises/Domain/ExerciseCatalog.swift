import Combine

protocol ExerciseCatalog {
    func fetchExerciseList() -> AnyPublisher<[Exercise], Error>
}
