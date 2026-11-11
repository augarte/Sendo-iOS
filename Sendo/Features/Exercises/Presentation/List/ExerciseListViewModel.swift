import Combine
import Foundation

@MainActor
final class ExerciseListViewModel: ObservableObject {
    enum State {
        case loading
        case loaded([Exercise])
        case failed(String)
    }

    @Published private(set) var state: State = .loading
    private let service: any ExerciseCatalog
    private var request: AnyCancellable?

    init(service: any ExerciseCatalog) {
        self.service = service
    }

    func fetchExercises() {
        switch state {
        case .loaded: break
        default: state = .loading
        }
        request = service.fetchExerciseList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard case .failure(let error) = completion else { return }
                if case .loaded = self?.state { return }
                self?.state = .failed(ExerciseCatalogError.message(for: error))
            } receiveValue: { [weak self] exercises in
                self?.state = .loaded(exercises)
            }
    }
}
