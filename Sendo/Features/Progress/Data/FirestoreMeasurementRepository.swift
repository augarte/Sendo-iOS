import Foundation
import FirebaseFirestore

struct FirestoreMeasurementRepository: MeasurementRepository {
    let database: Firestore
    let userID: String

    private var collection: CollectionReference {
        database.collection("users").document(userID).collection("measurements")
    }

    func fetch() async throws -> [BodyMeasurement] {
        try await fetch(source: .default)
    }

    func fetchForTransfer() async throws -> [BodyMeasurement] {
        try await database.waitForPendingWrites()
        return try await fetch(source: .server).filter { $0.value > 0 }
    }

    private func fetch(source: FirestoreSource) async throws -> [BodyMeasurement] {
        let snapshot = try await collection.getDocuments(source: source)
        return snapshot.documents.compactMap { document in
            MeasurementRecord.decode(id: document.documentID, fields: document.data())
        }
    }

    func importIfMissing(_ measurement: BodyMeasurement, id: MeasurementID) async throws {
        let document = collection.document(id)
        let fields = MeasurementRecord.fields(for: measurement)
        _ = try await database.runTransaction { transaction, errorPointer in
            do {
                if try !transaction.getDocument(document).exists {
                    transaction.setData(fields, forDocument: document)
                }
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    func create(_ measurement: BodyMeasurement) async throws {
        try await collection.document(measurement.id)
            .setData(MeasurementRecord.fields(for: measurement), merge: true)
    }

    func update(_ measurement: BodyMeasurement) async throws {
        try await collection.document(measurement.id)
            .updateData(MeasurementRecord.fields(for: measurement))
    }

    func delete(id: MeasurementID) async throws {
        try await collection.document(id).delete()
    }
}

enum MeasurementRecord {
    static func decode(id: String, fields: [String: Any]) -> BodyMeasurement? {
        guard let value = fields["value"] as? Double, value.isFinite else { return nil }
        let measuredAt: Date
        if let timestamp = fields["measuredAt"] as? Timestamp {
            measuredAt = timestamp.dateValue()
        } else if let seconds = Int(id) {
            measuredAt = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            return nil
        }

        let kind: BodyMeasurement.Kind
        if let rawKind = fields["kind"] as? String {
            guard let decoded = BodyMeasurement.Kind(rawValue: rawKind) else { return nil }
            kind = decoded
        } else {
            kind = .weight
        }

        let unit = (fields["unit"] as? String).flatMap(BodyMeasurement.Unit.init(rawValue:))
        return BodyMeasurement(id: id, measuredAt: measuredAt, kind: kind, value: value, unit: unit)
    }

    static func fields(for measurement: BodyMeasurement) -> [String: Any] {
        var fields: [String: Any] = [
            "value": measurement.value,
            "measuredAt": Timestamp(date: measurement.measuredAt),
            "kind": measurement.kind.rawValue
        ]
        if let unit = measurement.unit {
            fields["unit"] = unit.rawValue
        }
        return fields
    }
}
