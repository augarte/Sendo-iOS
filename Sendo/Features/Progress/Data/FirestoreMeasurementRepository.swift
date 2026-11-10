import Foundation
import FirebaseFirestore

struct FirestoreMeasurementRepository: MeasurementRepository {
    private let firestore: FirebaseFirestoreManager

    init(firestore: FirebaseFirestoreManager) {
        self.firestore = firestore
    }

    func fetch() async throws -> [BodyMeasurement] {
        let snapshot = try await collection().getDocuments()
        return snapshot.documents.compactMap { document in
            MeasurementRecord.decode(id: document.documentID, fields: document.data())
        }
    }

    func create(_ measurement: BodyMeasurement) async throws {
        try await collection().document(measurement.id)
            .setData(MeasurementRecord.fields(for: measurement), merge: true)
    }

    func update(_ measurement: BodyMeasurement) async throws {
        try await collection().document(measurement.id)
            .updateData(MeasurementRecord.fields(for: measurement))
    }

    func delete(id: MeasurementID) async throws {
        try await collection().document(id).delete()
    }

    private func collection() throws -> CollectionReference {
        try firestore.userCollection(named: "measurements")
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
