import Foundation
import CoreData

// ─────────────────────────────────────────────
// MARK: - ClienteService
// ─────────────────────────────────────────────

final class ClienteService {

    // MARK: Singleton
    static let shared = ClienteService()
    private init() {}

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.viewContext }

    // ─────────────────────────────────────────
    // MARK: - Fetch
    // ─────────────────────────────────────────

    /// All clients sorted by apellidos.
    /// - Parameter onlyActive: when true, excludes clients with estado == "Inactivo".
    func fetchAll(onlyActive: Bool = false) -> [Cliente] {
        persistence.fetch(Cliente.all(onlyActive: onlyActive))
    }

    /// Single client by primary key, or nil if not found.
    func fetch(byID id: UUID) -> Cliente? {
        persistence.fetch(Cliente.byID(id)).first
    }

    /// Single client by DNI, or nil if not found.
    func fetch(byDNI dni: String) -> Cliente? {
        persistence.fetch(Cliente.byDNI(dni.trimmed)).first
    }

    // ─────────────────────────────────────────
    // MARK: - Search & Filter
    // ─────────────────────────────────────────

    /// Full-text search across nombres, apellidos, and DNI.
    /// Returns all clients when `text` is empty.
    func search(text: String, onlyActive: Bool = false) -> [Cliente] {
        let trimmed = text.trimmed
        guard trimmed.isNotBlank else { return fetchAll(onlyActive: onlyActive) }
        return persistence.fetch(Cliente.search(text: trimmed, onlyActive: onlyActive))
    }

    /// Returns all clients matching the given status ("Activo" or "Inactivo").
    func filter(byStatus status: String) -> [Cliente] {
        let req = Cliente.fetchRequest()
        req.predicate       = NSPredicate(format: "estado == %@", status)
        req.sortDescriptors = [NSSortDescriptor(key: "apellidos", ascending: true)]
        return persistence.fetch(req)
    }

    // ─────────────────────────────────────────
    // MARK: - Validation
    // ─────────────────────────────────────────

    /// True when no other client uses this 8-digit DNI.
    ///
    /// Pass `excludingID` during edits so the client can keep its own DNI.
    func isDNIUnique(_ dni: String, excludingID: UUID? = nil) -> Bool {
        let req = Cliente.fetchRequest()

        if let excludeID = excludingID {
            req.predicate = NSPredicate(
                format: "dni == %@ AND idCliente != %@",
                dni.trimmed, excludeID as CVarArg
            )
        } else {
            req.predicate = NSPredicate(format: "dni == %@", dni.trimmed)
        }

        req.fetchLimit = 1
        return persistence.count(req) == 0
    }

    // ─────────────────────────────────────────
    // MARK: - Create
    // ─────────────────────────────────────────

    /// Insert a new client in the database.
    ///
    /// - Throws: `ServiceError.duplicateDNI` if the DNI is already taken.
    /// - Returns: The newly created `Cliente`.
    @discardableResult
    func create(
        dni:       String,
        nombres:   String,
        apellidos: String,
        telefono:  String? = nil,
        correo:    String? = nil,
        direccion: String? = nil
    ) throws -> Cliente {
        guard isDNIUnique(dni) else {
            throw ServiceError.duplicateDNI
        }

        let client            = Cliente(context: context)
        client.idCliente      = UUID()
        client.dni            = dni.trimmed
        client.nombres        = nombres.trimmed
        client.apellidos      = apellidos.trimmed
        client.telefono       = nonEmpty(telefono)
        client.correo         = nonEmpty(correo)
        client.direccion      = nonEmpty(direccion)
        client.estado         = "Activo"
        client.fechaRegistro  = Date()

        persistence.save()
        return client
    }

    // ─────────────────────────────────────────
    // MARK: - Update
    // ─────────────────────────────────────────

    /// Replace all mutable fields on an existing client.
    ///
    /// - Throws: `ServiceError.duplicateDNI` if the new DNI belongs to a different client.
    func update(
        _ client:  Cliente,
        dni:       String,
        nombres:   String,
        apellidos: String,
        telefono:  String?,
        correo:    String?,
        direccion: String?,
        estado:    String
    ) throws {
        let normalizedDNI = dni.trimmed
        if normalizedDNI != client.dniValue {
            guard isDNIUnique(normalizedDNI) else {
                throw ServiceError.duplicateDNI
            }
        }

        client.dni       = normalizedDNI
        client.nombres   = nombres.trimmed
        client.apellidos = apellidos.trimmed
        client.telefono  = nonEmpty(telefono)
        client.correo    = nonEmpty(correo)
        client.direccion = nonEmpty(direccion)
        client.estado    = estado

        persistence.save()
    }

    // ─────────────────────────────────────────
    // MARK: - Delete
    // ─────────────────────────────────────────

    /// Physically remove a client (and cascade-delete their Ubicaciones).
    /// Ventas referencing this client are nullified automatically.
    func delete(_ client: Cliente) {
        context.delete(client)
        persistence.save()
    }

    // ─────────────────────────────────────────
    // MARK: - Private Helpers
    // ─────────────────────────────────────────

    /// Returns the trimmed string if non-empty, otherwise nil.
    private func nonEmpty(_ value: String?) -> String? {
        let t = value?.trimmed
        return t?.isNotBlank == true ? t : nil
    }
}
