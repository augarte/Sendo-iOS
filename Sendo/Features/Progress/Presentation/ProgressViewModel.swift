import Combine
import Foundation

@MainActor
final class ProgressViewModel {
    struct State {
        var measurements: [BodyMeasurement] = []
        var isLoading = false
        var loadError: String?
    }

    @Published private(set) var state = State()
    private(set) var revision = UUID()
    private var repository: (any MeasurementRepository)?
    private var repositorySubscription: AnyCancellable?
    private var isWriting = false

    init(repository: (any MeasurementRepository)?) {
        self.repository = repository
    }

    func observeRepositories(_ repositories: AnyPublisher<(any MeasurementRepository)?, Never>) {
        repositorySubscription = repositories.sink { [weak self] repository in
            self?.replaceRepository(repository)
            Task { await self?.load() }
        }
    }

    func replaceRepository(_ repository: (any MeasurementRepository)?) {
        revision = UUID()
        self.repository = repository
        isWriting = false
        state = State()
    }

    func load() async {
        guard let repository, !state.isLoading, !isWriting else { return }
        let revision = self.revision
        state.isLoading = true
        state.loadError = nil
        defer {
            if revision == self.revision { state.isLoading = false }
        }

        do {
            let measurements = try await repository.fetch()
            guard revision == self.revision else { return }
            state.measurements = sorted(measurements)
        } catch {
            guard revision == self.revision else { return }
            state.loadError = error.localizedDescription
        }
    }

    func save(_ measurement: BodyMeasurement, isEditing: Bool, revision: UUID) async throws {
        try measurement.validate()
        let repository = try beginWrite(revision: revision)
        defer {
            if revision == self.revision { isWriting = false }
        }

        if isEditing {
            try await repository.update(measurement)
        } else {
            try await repository.create(measurement)
        }

        guard revision == self.revision else { throw WriteError.accountChanged }
        let remaining = state.measurements.filter { $0.id != measurement.id }
        state.measurements = sorted(remaining + [measurement])
    }

    func delete(id: MeasurementID, revision: UUID) async throws {
        let repository = try beginWrite(revision: revision)
        defer {
            if revision == self.revision { isWriting = false }
        }

        try await repository.delete(id: id)
        guard revision == self.revision else { throw WriteError.accountChanged }
        state.measurements.removeAll { $0.id == id }
    }

    private func beginWrite(revision: UUID) throws -> any MeasurementRepository {
        guard revision == self.revision else { throw WriteError.accountChanged }
        guard let repository else { throw WriteError.accountUnavailable }
        guard !state.isLoading, !isWriting else { throw WriteError.busy }
        isWriting = true
        return repository
    }

    private func sorted(_ measurements: [BodyMeasurement]) -> [BodyMeasurement] {
        measurements.sorted {
            if $0.measuredAt == $1.measuredAt { return $0.id < $1.id }
            return $0.measuredAt > $1.measuredAt
        }
    }

    private enum WriteError: LocalizedError {
        case busy, accountChanged, accountUnavailable

        var errorDescription: String? {
            switch self {
            case .busy: "Progress is busy. Please try again in a moment."
            case .accountChanged: "Your account changed. Reopen the measurement and try again."
            case .accountUnavailable: "Your account is unavailable. Please try again."
            }
        }
    }
}
