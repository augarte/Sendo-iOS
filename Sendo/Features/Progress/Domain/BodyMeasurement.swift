import Foundation

typealias MeasurementID = String

struct BodyMeasurement: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case weight
    }

    enum Unit: String, Codable {
        case kilograms = "kg"
        case pounds = "lb"
    }

    let id: MeasurementID
    let measuredAt: Date
    let kind: Kind
    let value: Double
    let unit: Unit?

    func validate() throws {
        guard value.isFinite, value > 0 else {
            throw MeasurementError.invalidValue
        }
    }
}

enum MeasurementError: LocalizedError {
    case invalidValue

    var errorDescription: String? { "Enter a weight greater than zero." }
}

@MainActor
protocol MeasurementRepository {
    func fetch() async throws -> [BodyMeasurement]
    func create(_ measurement: BodyMeasurement) async throws
    func update(_ measurement: BodyMeasurement) async throws
    func delete(id: MeasurementID) async throws
}
