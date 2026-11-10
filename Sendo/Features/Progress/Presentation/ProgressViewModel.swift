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
    private let repository: any MeasurementRepository
    private var isWriting = false

    init(repository: any MeasurementRepository) {
        self.repository = repository
    }

    func load() async {
        guard !state.isLoading, !isWriting else { return }
        state.isLoading = true
        state.loadError = nil
        defer { state.isLoading = false }

        do {
            state.measurements = sorted(try await repository.fetch())
        } catch {
            state.loadError = error.localizedDescription
        }
    }

    func save(_ measurement: BodyMeasurement, isEditing: Bool) async throws {
        try measurement.validate()
        guard !state.isLoading, !isWriting else { throw WriteError.busy }
        isWriting = true
        defer { isWriting = false }

        if isEditing {
            try await repository.update(measurement)
        } else {
            try await repository.create(measurement)
        }

        let remaining = state.measurements.filter { $0.id != measurement.id }
        state.measurements = sorted(remaining + [measurement])
    }

    func delete(id: MeasurementID) async throws {
        guard !state.isLoading, !isWriting else { throw WriteError.busy }
        isWriting = true
        defer { isWriting = false }

        try await repository.delete(id: id)
        state.measurements.removeAll { $0.id == id }
    }

    private func sorted(_ measurements: [BodyMeasurement]) -> [BodyMeasurement] {
        measurements.sorted {
            if $0.measuredAt == $1.measuredAt { return $0.id < $1.id }
            return $0.measuredAt > $1.measuredAt
        }
    }

    private enum WriteError: LocalizedError {
        case busy

        var errorDescription: String? { "Progress is busy. Please try again in a moment." }
    }
}
