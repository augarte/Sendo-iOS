import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Testing

#if DEBUG
@testable import Sendo_Dev
#else
@testable import Sendo
#endif

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.arguments.contains("--sendo-emulator-tests")))
struct FirebaseIntegrationTests {
    @Test @MainActor
    func testMeasurementLifecycleAndRules() async throws {
        let backend = try makeBackend()
        defer { backend.close() }

        let user = try await backend.auth.signInAnonymously().user
        let repository = backend.measurements(for: user.uid)
        try await backend.seedLegacyMeasurement(for: user.uid)
        let legacyEntries = try await repository.fetch()
        let legacy = try #require(legacyEntries.first)
        #expect(legacy.id == "1700000000")
        #expect(legacy.measuredAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(legacy.unit == nil)

        let created = BodyMeasurement(
            id: "new-measurement", measuredAt: Date(timeIntervalSince1970: 1_700_000_010),
            kind: .weight, value: 74.5, unit: .kilograms
        )
        try await repository.create(created)
        try await repository.create(created)
        let edited = BodyMeasurement(
            id: legacy.id, measuredAt: Date(timeIntervalSince1970: 1_600_000_000),
            kind: .weight, value: 73, unit: legacy.unit
        )
        try await repository.update(edited)
        let entries = try await repository.fetch()
        #expect(Set(entries.map(\.id)) == Set([legacy.id, created.id]))
        #expect(entries.first(where: { $0.id == legacy.id }) == edited)

        try await repository.delete(id: created.id)
        let remaining = try await repository.fetch()
        #expect(remaining == [edited])

        try backend.auth.signOut()
        _ = try await backend.auth.signInAnonymously()
        let foreignDocument = backend.database.collection("users").document(user.uid)
            .collection("measurements").document(legacy.id)
        await assertPermissionDenied {
            _ = try await foreignDocument.getDocument(source: .server)
        }
        await assertPermissionDenied {
            try await repository.update(edited)
        }
    }

    @Test @MainActor
    func testGuestLinksToNewProviderAndKeepsHistory() async throws {
        let backend = try makeBackend()
        defer { backend.close() }
        let session = backend.session()
        let guest = try await startGuest(session)
        let original = sampleMeasurement(value: 72.5)
        try await backend.measurements(for: guest.uid).create(original)

        let subject = UUID().uuidString
        let account = try await session.signIn(with: googleCredential(subject), providerUserID: subject)
        #expect(account.uid == guest.uid)
        #expect(!(account.isGuest))
        #expect(session.account == account)
        let entries = try await backend.measurements(for: account.uid).fetch()
        #expect(entries == [original])
    }

    @Test @MainActor
    func testGuestMergesIntoExistingAccountWithoutOverwritingHistory() async throws {
        let backend = try makeBackend()
        defer { backend.close() }
        let subject = UUID().uuidString
        let existing = try await backend.auth.signIn(with: googleCredential(subject)).user
        let original = sampleMeasurement(value: 72.5)
        try await backend.measurements(for: existing.uid).create(original)
        try backend.auth.signOut()

        let session = backend.session()
        let guest = try await startGuest(session)
        let guestEntry = sampleMeasurement(value: 75)
        try await backend.measurements(for: guest.uid).create(guestEntry)
        let account = try await session.signIn(with: googleCredential(subject), providerUserID: subject)

        #expect(account.uid == existing.uid)
        #expect(session.account == account)
        let repository = backend.measurements(for: existing.uid)
        let merged = try await repository.fetch()
        #expect(merged.count == 2)
        #expect(merged.contains(original))
        #expect(merged.first(where: { $0.id != original.id })?.value == guestEntry.value)
        await session.resumePendingMerges()
        let repeated = try await repository.fetch()
        #expect(Set(repeated.map(\.id)) == Set(merged.map(\.id)))
    }

    @Test @MainActor
    func testInterruptedTransferResumesOnlyForItsDestinationAndKeepsEdits() async throws {
        let backend = try makeBackend()
        defer { backend.close() }
        let guest = try await backend.auth.signInAnonymously().user
        try await backend.measurements(for: guest.uid).create(sampleMeasurement(value: 75))

        let destination = UUID().uuidString
        let merges = GuestMeasurementMerges(database: backend.database, directory: backend.directory)
        try await merges.stage(
            sourceUID: guest.uid, destination: .init(provider: "google.com", uid: destination)
        )
        let files = try FileManager.default.contentsOfDirectory(at: backend.directory, includingPropertiesForKeys: nil)
        let transferFile = try #require(files.first)
        let staged = try Data(contentsOf: transferFile)

        let other = try await backend.auth.signIn(with: googleCredential(UUID().uuidString)).user
        let didTransferToOther = try await merges.resume(for: other)
        #expect(!(didTransferToOther))
        #expect(FileManager.default.fileExists(atPath: transferFile.path))
        let otherEntries = try await backend.measurements(for: other.uid).fetch()
        #expect(otherEntries.isEmpty)

        let user = try await backend.auth.signIn(with: googleCredential(destination)).user
        let didTransfer = try await merges.resume(for: user)
        #expect(didTransfer)
        let repository = backend.measurements(for: user.uid)
        let entries = try await repository.fetch()
        let copied = try #require(entries.first)
        let edited = BodyMeasurement(id: copied.id, measuredAt: copied.measuredAt, kind: .weight, value: 76, unit: nil)
        try await repository.update(edited)
        try staged.write(to: transferFile)

        _ = try await merges.resume(for: user)
        let retried = try await repository.fetch()
        #expect(retried == [edited])
    }

    @MainActor
    private func startGuest(_ session: FirebaseSessionStore) async throws -> FirebaseSessionStore.Account {
        session.start()
        for _ in 0..<100 {
            if let account = session.account {
                #expect(account.isGuest)
                return account
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        throw CocoaError(.validationMissingMandatoryProperty)
    }

    private func sampleMeasurement(value: Double) -> BodyMeasurement {
        BodyMeasurement(
            id: "same-id", measuredAt: Date(timeIntervalSince1970: 1_700_000_000),
            kind: .weight, value: value, unit: nil
        )
    }

    private func googleCredential(_ subject: String) -> AuthCredential {
        GoogleAuthProvider.credential(withIDToken: #"{"sub":"\#(subject)"}"#, accessToken: "")
    }

    @MainActor
    private func assertPermissionDenied(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            Issue.record("Expected the Firestore rules to deny access")
        } catch {
            #expect((error as NSError).code == FirestoreErrorCode.permissionDenied.rawValue)
        }
    }

    @MainActor
    private func makeBackend() throws -> Backend {
        try #require(AppEnvironment.usesFixtures, "Integration tests require fixture startup.")
        let options = FirebaseOptions(googleAppID: "1:1234567890:ios:0123456789abcdef", gcmSenderID: "1234567890")
        options.projectID = "demo-sendo"
        // The SDK validates the key shape even for a loopback-only demo project.
        options.apiKey = "A" + String(repeating: "0", count: 38)
        let name = "SendoIntegration-" + UUID().uuidString
        FirebaseApp.configure(name: name, options: options)
        let app = try #require(FirebaseApp.app(name: name))
        let auth = Auth.auth(app: app)
        auth.useEmulator(withHost: "127.0.0.1", port: 9099)
        let database = Firestore.firestore(app: app)
        let settings = database.settings
        settings.host = "127.0.0.1:8080"
        settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        database.settings = settings
        return Backend(app: app, auth: auth, database: database)
    }
}

@MainActor
private struct Backend {
    let app: FirebaseApp
    let auth: Auth
    let database: Firestore
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    func measurements(for userID: String) -> FirestoreMeasurementRepository {
        FirestoreMeasurementRepository(database: database, userID: userID)
    }

    func session() -> FirebaseSessionStore {
        FirebaseSessionStore(auth: auth, database: database, mergeDirectory: directory)
    }

    func seedLegacyMeasurement(for uid: String) async throws {
        let endpoint = "http://127.0.0.1:8080/v1/projects/demo-sendo/databases/(default)/documents"
        let url = URL(string: endpoint + "/users/" + uid + "/measurements/1700000000")!
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = "PATCH"
        request.setValue("Bearer owner", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(#"{"fields":{"value":{"doubleValue":72.5}}}"#.utf8)
        let (_, response) = try await URLSession.shared.data(for: request)
        #expect((response as? HTTPURLResponse)?.statusCode == 200)
    }

    func close() {
        try? auth.signOut()
        app.delete { _ in }
        try? FileManager.default.removeItem(at: directory)
    }
}
