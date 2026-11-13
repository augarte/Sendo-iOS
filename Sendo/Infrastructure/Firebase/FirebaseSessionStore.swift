import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirebaseSessionStore {
    struct Account: Equatable {
        let uid: String
        let name: String?
        let isGuest: Bool
        let photoURL: URL?
    }

    @Published private(set) var account: Account?
    private let auth: Auth
    private let database: Firestore
    private let merges: GuestMeasurementMerges
    private var authListener: NSObjectProtocol?
    private var bootstrapsGuest = true
    private var isTransitioning = false

    init(auth: Auth, database: Firestore, mergeDirectory: URL) {
        self.auth = auth
        self.database = database
        self.merges = GuestMeasurementMerges(database: database, directory: mergeDirectory)
    }

    deinit {
        if let authListener { auth.removeStateDidChangeListener(authListener) }
    }

    func start() {
        guard authListener == nil else { return }
        authListener = auth.addStateDidChangeListener { [weak self] _, _ in
            Task { @MainActor in await self?.restoreAccount() }
        }
    }

    func signIn(with credential: AuthCredential, providerUserID: String) async throws -> Account {
        guard !isTransitioning, !bootstrapsGuest else { throw SessionError.busy }
        isTransitioning = true
        defer {
            publishAccount()
            isTransitioning = false
        }

        let result: AuthDataResult
        if let guest = auth.currentUser, guest.isAnonymous {
            do {
                result = try await guest.link(with: credential)
            } catch {
                let authError = error as NSError
                guard authError.domain == AuthErrorDomain,
                      authError.code == AuthErrorCode.credentialAlreadyInUse.rawValue else {
                    throw error
                }
                account = nil
                let destination = GuestMeasurementMerges.ProviderIdentity(
                    provider: credential.provider, uid: providerUserID
                )
                try await merges.stage(sourceUID: guest.uid, destination: destination)
                let updatedCredential = authError.userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? AuthCredential
                result = try await auth.signIn(with: updatedCredential ?? credential)
            }
        } else {
            account = nil
            result = try await auth.signIn(with: credential)
        }

        _ = try await merges.resume(for: result.user)
        return makeAccount(result.user)
    }

    func signOut() throws {
        guard !isTransitioning, !bootstrapsGuest else { throw SessionError.busy }
        try auth.signOut()
        publishAccount()
    }

    func resumePendingMerges() async {
        guard !isTransitioning, !bootstrapsGuest, let user = auth.currentUser, !user.isAnonymous else { return }
        isTransitioning = true
        defer {
            publishAccount()
            isTransitioning = false
        }
        do {
            if try await merges.resume(for: user) {
                account = nil
            }
        } catch {
            NSLog("A pending guest measurement transfer will be retried.")
        }
    }

    private func restoreAccount() async {
        guard !isTransitioning else { return }
        if bootstrapsGuest {
            bootstrapsGuest = false
            if auth.currentUser == nil {
                isTransitioning = true
                do {
                    _ = try await auth.signInAnonymously()
                } catch {
                    NSLog("Sendo couldn’t restore a guest session.")
                }
                isTransitioning = false
            }
        }
        await resumePendingMerges()
        publishAccount()
    }

    private func publishAccount() {
        let current = auth.currentUser.map(makeAccount)
        if current != account { account = current }
    }

    private func makeAccount(_ user: User) -> Account {
        let photo = user.photoURL ?? user.providerData.lazy.compactMap(\.photoURL).first
        return Account(uid: user.uid, name: user.displayName, isGuest: user.isAnonymous, photoURL: photo.map(Self.sharper))
    }

    /// Google serves a 96-pixel avatar by default, which is soft at the size the profile shows it.
    private static func sharper(_ url: URL) -> URL {
        URL(string: url.absoluteString.replacingOccurrences(of: "=s96-c", with: "=s256-c")) ?? url
    }

    private enum SessionError: LocalizedError {
        case busy

        var errorDescription: String? { "Sendo is finishing an account change. Please try again." }
    }
}
