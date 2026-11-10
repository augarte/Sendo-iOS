import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
struct GuestMeasurementMerges {
    struct ProviderIdentity: Codable, Equatable {
        let provider: String
        let uid: String
    }

    private struct Pending: Codable {
        let sourceUID: String
        let destination: ProviderIdentity
        let measurements: [BodyMeasurement]
    }

    let database: Firestore
    let directory: URL

    func stage(sourceUID: String, destination: ProviderIdentity) async throws {
        let repository = FirestoreMeasurementRepository(database: database, userID: sourceUID)
        let measurements = try await repository.fetchForTransfer()

        let pending = Pending(sourceUID: sourceUID, destination: destination, measurements: measurements)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var storage = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try storage.setResourceValues(values)
        let filename = digest(sourceUID) + ".json"
        try JSONEncoder().encode(pending).write(
            to: directory.appendingPathComponent(filename),
            options: [.atomic, .completeFileProtection]
        )
    }

    func resume(for user: User) async throws -> Bool {
        guard !user.isAnonymous, FileManager.default.fileExists(atPath: directory.path) else { return false }
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let identities = user.providerData.map { ProviderIdentity(provider: $0.providerID, uid: $0.uid) }
        let repository = FirestoreMeasurementRepository(database: database, userID: user.uid)

        var transferred = false
        for file in files where file.pathExtension == "json" {
            let pending = try JSONDecoder().decode(Pending.self, from: Data(contentsOf: file))
            guard identities.contains(pending.destination) else { continue }

            for measurement in pending.measurements {
                let id = "guest-" + digest(pending.sourceUID + "/" + measurement.id)
                try await repository.importIfMissing(measurement, id: id)
            }
            try FileManager.default.removeItem(at: file)
            transferred = transferred || !pending.measurements.isEmpty
        }
        return transferred
    }

    private func digest(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
