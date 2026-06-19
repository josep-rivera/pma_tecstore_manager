import Foundation
import CoreData

// ─────────────────────────────────────────────
// MARK: - ProductoService
// ─────────────────────────────────────────────

final class ProductoService {

    // MARK: Singleton
    static let shared = ProductoService()
    private init() {}

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.viewContext }

    // ─────────────────────────────────────────
    // MARK: - Fetch
    // ─────────────────────────────────────────

    /// All products, sorted by name.
    /// - Parameter onlyActive: when true, excludes products with estado == "Inactivo".
    func fetchAll(onlyActive: Bool = false) -> [Producto] {
        persistence.fetch(Producto.all(onlyActive: onlyActive))
    }

    /// Single product by primary key, or nil if not found.
    func fetch(byID id: UUID) -> Producto? {
        persistence.fetch(Producto.byID(id)).first
    }

    // ─────────────────────────────────────────
    // MARK: - Search & Filter
    // ─────────────────────────────────────────

    /// Full-text search across nombre, codigo, and categoria.
    /// Returns all products when `text` is empty.
    func search(text: String, onlyActive: Bool = false) -> [Producto] {
        let trimmed = text.trimmed
        guard trimmed.isNotBlank else { return fetchAll(onlyActive: onlyActive) }
        return persistence.fetch(Producto.search(text: trimmed, onlyActive: onlyActive))
    }

    /// Filter by a specific category from `ProductCategory`.
    func filter(byCategory category: String, onlyActive: Bool = false) -> [Producto] {
        let req = Producto.fetchRequest()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "categoria == %@", category)
        ]
        if onlyActive {
            predicates.append(NSPredicate(format: "estado == %@", "Activo"))
        }
        req.predicate       = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        req.sortDescriptors = [NSSortDescriptor(key: "nombre", ascending: true)]
        return persistence.fetch(req)
    }

    /// Products with stock at or below the threshold, ascending by stock.
    func fetchLowStock(threshold: Int32 = 5) -> [Producto] {
        persistence.fetch(Producto.lowStock(threshold: threshold))
    }

    /// The single active product with the fewest units.
    func fetchLowestStockProduct() -> Producto? {
        persistence.fetch(Producto.lowestStockProduct()).first
    }

    // ─────────────────────────────────────────
    // MARK: - Code Generation
    // ─────────────────────────────────────────

    func generateCode(for category: String) -> String {
        let prefix = categoryPrefix(for: category)
        let req = Producto.fetchRequest()
        req.predicate = NSPredicate(format: "codigo BEGINSWITH[c] %@", prefix + "-")
        let existing = (try? context.fetch(req)) ?? []
        let maxNum = existing.compactMap { p -> Int? in
            guard let code = p.codigo else { return nil }
            let parts = code.split(separator: "-")
            return parts.count == 2 ? Int(parts[1]) : nil
        }.max() ?? 0
        return String(format: "%@-%03d", prefix, maxNum + 1)
    }

    private func categoryPrefix(for category: String) -> String {
        switch category {
        case "Electrónica": return "ELEC"
        case "Ropa":        return "ROPA"
        case "Alimentos":   return "ALIM"
        case "Limpieza":    return "LIMP"
        case "Hogar":       return "HOGAR"
        case "Tecnología":  return "TEC"
        case "Deportes":    return "DEPO"
        case "Otros":       return "OTROS"
        default:            return "PRD"
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Validation
    // ─────────────────────────────────────────

    /// True when no other product uses this code (case-insensitive).
    ///
    /// Pass `excludingID` during edits to allow keeping the same code.
    func isCodeUnique(_ code: String, excludingID: UUID? = nil) -> Bool {
        let normalizedCode = code.trimmed.uppercased()
        let req = Producto.fetchRequest()

        if let excludeID = excludingID {
            req.predicate = NSPredicate(
                format: "codigo ==[cd] %@ AND idProducto != %@",
                normalizedCode, excludeID as CVarArg
            )
        } else {
            req.predicate = NSPredicate(format: "codigo ==[cd] %@", normalizedCode)
        }

        req.fetchLimit = 1
        return persistence.count(req) == 0
    }

    // ─────────────────────────────────────────
    // MARK: - Create
    // ─────────────────────────────────────────

    /// Insert a new product in the database.
    ///
    /// - Throws: `ServiceError.duplicateCode` if the code is already taken.
    /// - Returns: The newly created `Producto`.
    @discardableResult
    func create(
        code:      String,
        name:      String,
        category:  String,
        price:     Decimal,
        stock:     Int,
        photoPath: String? = nil
    ) throws -> Producto {
        let normalizedCode = code.trimmed.uppercased()

        guard isCodeUnique(normalizedCode) else {
            throw ServiceError.duplicateCode(normalizedCode)
        }

        let product           = Producto(context: context)
        product.idProducto    = UUID()
        product.codigo        = normalizedCode
        product.nombre        = name.trimmed
        product.categoria     = category
        product.precio        = NSDecimalNumber(decimal: price)
        product.stock         = Int32(max(0, stock))
        product.fotoProducto  = photoPath?.trimmed.isNotBlank == true ? photoPath : nil
        product.estado        = "Activo"
        product.fechaRegistro = Date()

        persistence.save()
        return product
    }

    // ─────────────────────────────────────────
    // MARK: - Update
    // ─────────────────────────────────────────

    /// Replace all mutable fields on an existing product.
    ///
    /// - Throws: `ServiceError.duplicateCode` if the new code belongs to a different product.
    func update(
        _ product:  Producto,
        code:       String,
        name:       String,
        category:   String,
        price:      Decimal,
        stock:      Int,
        photoPath:  String?,
        estado:     String
    ) throws {
        let normalizedCode = code.trimmed.uppercased()

        if normalizedCode != product.productCode {
            guard isCodeUnique(normalizedCode) else {
                throw ServiceError.duplicateCode(normalizedCode)
            }
        }

        product.codigo       = normalizedCode
        product.nombre       = name.trimmed
        product.categoria    = category
        product.precio       = NSDecimalNumber(decimal: price)
        product.stock        = Int32(max(0, stock))
        product.fotoProducto = photoPath?.trimmed.isNotBlank == true ? photoPath : nil
        product.estado       = estado

        persistence.save()
    }

    // ─────────────────────────────────────────
    // MARK: - Delete
    // ─────────────────────────────────────────

    /// Physically remove a product from the database (swipe-to-delete).
    func delete(_ product: Producto) {
        context.delete(product)
        persistence.save()
    }
}
