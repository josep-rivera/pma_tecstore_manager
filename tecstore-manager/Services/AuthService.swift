import Foundation
import CoreData

// ─────────────────────────────────────────────
// MARK: - ServiceError  (usado por todos los Services)
// ─────────────────────────────────────────────

enum ServiceError: LocalizedError {
    case notFound
    case duplicateEmail
    case duplicateDNI
    case duplicateCode(String)
    case invalidCredentials
    case insufficientStock(productName: String, available: Int)
    case emptyCart
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Registro no encontrado."
        case .duplicateEmail:
            return "El correo ya está registrado. Usa otro correo."
        case .duplicateDNI:
            return "El DNI ya está registrado."
        case .duplicateCode(let code):
            return "El código '\(code)' ya existe. Elige otro código."
        case .invalidCredentials:
            return "Correo o contraseña incorrectos."
        case .insufficientStock(let name, let qty):
            return "Stock insuficiente para \"\(name)\". Disponible: \(qty) ud."
        case .emptyCart:
            return "Debe agregar al menos un producto a la venta."
        case .unknown(let msg):
            return msg.isEmpty ? "Ocurrió un error inesperado." : msg
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - AuthService
// ─────────────────────────────────────────────

final class AuthService {

    // MARK: Singleton
    static let shared = AuthService()
    private init() {}

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.viewContext }

    // ─────────────────────────────────────────
    // MARK: - Session State
    // ─────────────────────────────────────────

    /// True when a user UUID is persisted in UserDefaults.
    var hasActiveSession: Bool {
        UserDefaults.standard.string(forKey: UserDefaultsKeys.activeUserID) != nil
    }

    /// Resolves the logged-in Usuario from Core Data using the stored UUID.
    var currentUser: Usuario? {
        guard
            let raw = UserDefaults.standard.string(forKey: UserDefaultsKeys.activeUserID),
            let id  = UUID(uuidString: raw)
        else { return nil }
        return persistence.fetch(Usuario.byID(id)).first
    }

    // ─────────────────────────────────────────
    // MARK: - Login
    // ─────────────────────────────────────────

    /// Validates credentials and saves the session to UserDefaults.
    ///
    /// - Throws: `ServiceError.invalidCredentials` on email/password mismatch.
    func login(email: String, password: String) throws {
        let normalizedEmail = email.lowercased().trimmed
        let matches         = persistence.fetch(Usuario.byEmail(normalizedEmail))

        guard let user = matches.first,
              PasswordHasher.verify(password, against: user.passwordHashValue) else {
            throw ServiceError.invalidCredentials
        }

        saveSession(userID: user.id)
    }

    // ─────────────────────────────────────────
    // MARK: - Register
    // ─────────────────────────────────────────

    /// Creates a new user, starts a session, and returns the new entity.
    ///
    /// - Throws: `ServiceError.duplicateEmail` if the address is already taken.
    @discardableResult
    func register(fullName: String, email: String, password: String) throws -> Usuario {
        let normalizedEmail = email.lowercased().trimmed

        guard persistence.fetch(Usuario.byEmail(normalizedEmail)).isEmpty else {
            throw ServiceError.duplicateEmail
        }

        let user            = Usuario(context: context)
        user.idUsuario      = UUID()
        user.nombreCompleto = fullName.trimmed
        user.correo         = normalizedEmail
        user.passwordHash   = PasswordHasher.hash(password)
        user.fechaRegistro  = Date()
        persistence.save()

        saveSession(userID: user.id)
        return user
    }

    // ─────────────────────────────────────────
    // MARK: - Logout
    // ─────────────────────────────────────────

    /// Clears the session and posts `.userDidLogout` so SceneDelegate
    /// can transition to the auth flow.
    func logout() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.activeUserID)
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }

    // ─────────────────────────────────────────
    // MARK: - Change Password
    // ─────────────────────────────────────────

    /// Verifies the current password before replacing it with a new SHA-256 hash.
    ///
    /// - Throws: `ServiceError.notFound` or `ServiceError.invalidCredentials`.
    func changePassword(current: String, new: String) throws {
        guard let user = currentUser else { throw ServiceError.notFound }

        guard PasswordHasher.verify(current, against: user.passwordHashValue) else {
            throw ServiceError.invalidCredentials
        }

        user.passwordHash = PasswordHasher.hash(new)
        persistence.save()
    }

    // ─────────────────────────────────────────
    // MARK: - Update Profile
    // ─────────────────────────────────────────

    /// Updates the display name and optionally the profile photo path.
    func updateProfile(fullName: String, photoPath: String?) {
        guard let user = currentUser else { return }
        if fullName.isNotBlank { user.nombreCompleto = fullName.trimmed }
        if let path = photoPath, path.isNotBlank { user.fotoPerfil = path }
        persistence.save()
    }

    // ─────────────────────────────────────────
    // MARK: - Private Helpers
    // ─────────────────────────────────────────

    private func saveSession(userID: UUID) {
        UserDefaults.standard.set(userID.uuidString, forKey: UserDefaultsKeys.activeUserID)
    }
}
