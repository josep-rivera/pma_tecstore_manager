import Foundation
import CoreData

/*
 CoreDataModels.swift
 Manual NSManagedObject subclasses for all 6 TecStore entities.
 Because we write these by hand (Manual/None codegen in the .xcdatamodeld),
 Xcode will NOT auto-generate conflicting files.

 Each entity block follows the same structure:
   1. Class declaration   — @objc(EntityName) + class body (empty)
   2. Properties extension — @NSManaged attributes + relationship accessors
   3. Identifiable        — public var id
   4. Convenience extension — safe-unwrap computed properties + fetch requests
*/

// ══════════════════════════════════════════════════════════
// MARK: - Usuario
// ══════════════════════════════════════════════════════════

@objc(Usuario)
public class Usuario: NSManagedObject {}

extension Usuario {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Usuario> {
        NSFetchRequest<Usuario>(entityName: "Usuario")
    }

    // MARK: Attributes
    @NSManaged public var idUsuario:       UUID?
    @NSManaged public var nombreCompleto:  String?
    @NSManaged public var correo:          String?
    @NSManaged public var passwordHash:    String?
    @NSManaged public var fotoPerfil:      String?       // nullable — file path
    @NSManaged public var fechaRegistro:   Date?

    // MARK: Relationships
    @NSManaged public var ventas: NSSet?   // → [Venta]  (to-many)

    // MARK: to-many Accessors
    @objc(addVentasObject:)    @NSManaged public func addToVentas(_ value: Venta)
    @objc(removeVentasObject:) @NSManaged public func removeFromVentas(_ value: Venta)
    @objc(addVentas:)          @NSManaged public func addToVentas(_ values: NSSet)
    @objc(removeVentas:)       @NSManaged public func removeFromVentas(_ values: NSSet)
}

extension Usuario: Identifiable {
    public var id: UUID { idUsuario ?? UUID() }
}

extension Usuario {

    // Safe-unwrap computed properties
    var fullName: String          { nombreCompleto ?? "" }
    var email: String             { correo ?? "" }
    var passwordHashValue: String { passwordHash ?? "" }
    var profileImagePath: String? { fotoPerfil }
    var registrationDate: Date    { fechaRegistro ?? Date() }

    var ventasArray: [Venta] {
        (ventas?.allObjects as? [Venta] ?? [])
            .sorted { ($0.fechaVenta ?? Date()) > ($1.fechaVenta ?? Date()) }
    }

    // MARK: Fetch Requests

    /// Fetch a single user by email address.
    static func byEmail(_ email: String) -> NSFetchRequest<Usuario> {
        let req = fetchRequest()
        req.predicate  = NSPredicate(format: "correo ==[cd] %@", email)
        req.fetchLimit = 1
        return req
    }

    /// Fetch a single user by UUID.
    static func byID(_ id: UUID) -> NSFetchRequest<Usuario> {
        let req = fetchRequest()
        req.predicate  = NSPredicate(format: "idUsuario == %@", id as CVarArg)
        req.fetchLimit = 1
        return req
    }
}

// ══════════════════════════════════════════════════════════
// MARK: - Producto
// ══════════════════════════════════════════════════════════

@objc(Producto)
public class Producto: NSManagedObject {}

extension Producto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Producto> {
        NSFetchRequest<Producto>(entityName: "Producto")
    }

    // MARK: Attributes
    @NSManaged public var idProducto:    UUID?
    @NSManaged public var codigo:        String?
    @NSManaged public var nombre:        String?
    @NSManaged public var categoria:     String?
    @NSManaged public var precio:        NSDecimalNumber?  // Decimal attribute → NSDecimalNumber
    @NSManaged public var stock:         Int32              // usesScalarValueType = YES → non-optional
    @NSManaged public var fotoProducto:  String?
    @NSManaged public var estado:        String?
    @NSManaged public var fechaRegistro: Date?

    // MARK: Relationships
    @NSManaged public var detalles: NSSet?   // → [DetalleVenta]  (to-many)

    // MARK: to-many Accessors
    @objc(addDetallesObject:)    @NSManaged public func addToDetalles(_ value: DetalleVenta)
    @objc(removeDetallesObject:) @NSManaged public func removeFromDetalles(_ value: DetalleVenta)
    @objc(addDetalles:)          @NSManaged public func addToDetalles(_ values: NSSet)
    @objc(removeDetalles:)       @NSManaged public func removeFromDetalles(_ values: NSSet)
}

extension Producto: Identifiable {
    public var id: UUID { idProducto ?? UUID() }
}

extension Producto {

    var productCode: String       { codigo ?? "" }
    var productName: String       { nombre ?? "" }
    var categoryValue: String     { categoria ?? ProductCategory.otros.rawValue }
    var priceDecimal: Decimal     { precio?.decimalValue ?? 0 }
    var priceDouble: Double       { precio?.doubleValue  ?? 0 }
    var stockInt: Int             { Int(stock) }
    var productImagePath: String? { fotoProducto }
    var statusValue: String       { estado ?? "Activo" }
    var registrationDate: Date    { fechaRegistro ?? Date() }
    var isActive: Bool            { statusValue == "Activo" }
    var hasStock: Bool            { stock > 0 }
    var categoryEnum: ProductCategory { ProductCategory(rawValue: categoryValue) ?? .otros }
    var detallesArray: [DetalleVenta] { detalles?.allObjects as? [DetalleVenta] ?? [] }

    // MARK: Fetch Requests

    static func all(onlyActive: Bool = false) -> NSFetchRequest<Producto> {
        let req = fetchRequest()
        req.predicate = onlyActive
            ? NSPredicate(format: "estado == %@", "Activo")
            : nil
        req.sortDescriptors = [NSSortDescriptor(key: "nombre", ascending: true,
                                                 selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        return req
    }

    static func byCode(_ code: String) -> NSFetchRequest<Producto> {
        let req = fetchRequest()
        req.predicate  = NSPredicate(format: "codigo ==[cd] %@", code)
        req.fetchLimit = 1
        return req
    }

    static func byID(_ id: UUID) -> NSFetchRequest<Producto> {
        let req = fetchRequest()
        req.predicate  = NSPredicate(format: "idProducto == %@", id as CVarArg)
        req.fetchLimit = 1
        return req
    }

    static func search(text: String, onlyActive: Bool = false) -> NSFetchRequest<Producto> {
        let req = fetchRequest()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "nombre CONTAINS[cd] %@ OR codigo CONTAINS[cd] %@ OR categoria CONTAINS[cd] %@",
                        text, text, text)
        ]
        if onlyActive {
            predicates.append(NSPredicate(format: "estado == %@", "Activo"))
        }
        req.predicate       = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        req.sortDescriptors = [NSSortDescriptor(key: "nombre", ascending: true)]
        return req
    }

    /// Products with stock ≤ threshold that are active.
    static func lowStock(threshold: Int32 = 5) -> NSFetchRequest<Producto> {
        let req = fetchRequest()
        req.predicate       = NSPredicate(format: "stock <= %d AND estado == %@", threshold, "Activo")
        req.sortDescriptors = [NSSortDescriptor(key: "stock", ascending: true)]
        return req
    }

    /// The single active product with the lowest stock value.
    static func lowestStockProduct() -> NSFetchRequest<Producto> {
        let req = fetchRequest()
        req.predicate       = NSPredicate(format: "estado == %@", "Activo")
        req.sortDescriptors = [NSSortDescriptor(key: "stock", ascending: true)]
        req.fetchLimit      = 1
        return req
    }
}

// ══════════════════════════════════════════════════════════
// MARK: - Cliente
// ══════════════════════════════════════════════════════════

@objc(Cliente)
public class Cliente: NSManagedObject {}

extension Cliente {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Cliente> {
        NSFetchRequest<Cliente>(entityName: "Cliente")
    }

    // MARK: Attributes
    @NSManaged public var idCliente:     UUID?
    @NSManaged public var dni:           String?
    @NSManaged public var nombres:       String?
    @NSManaged public var apellidos:     String?
    @NSManaged public var telefono:      String?    // optional
    @NSManaged public var correo:        String?    // optional
    @NSManaged public var direccion:     String?    // optional
    @NSManaged public var estado:        String?
    @NSManaged public var fechaRegistro: Date?

    // MARK: Relationships
    @NSManaged public var ubicacion: Ubicacion?   // → Ubicacion (to-one, cascade)
    @NSManaged public var ventas: NSSet?    // → [Venta] (to-many, nullify)

    // MARK: to-many Accessors
    @objc(addVentasObject:)    @NSManaged public func addToVentas(_ value: Venta)
    @objc(removeVentasObject:) @NSManaged public func removeFromVentas(_ value: Venta)
    @objc(addVentas:)          @NSManaged public func addToVentas(_ values: NSSet)
    @objc(removeVentas:)       @NSManaged public func removeFromVentas(_ values: NSSet)
}

extension Cliente: Identifiable {
    public var id: UUID { idCliente ?? UUID() }
}

extension Cliente {

    var dniValue: String          { dni ?? "" }
    var firstNames: String        { nombres ?? "" }
    var lastNames: String         { apellidos ?? "" }
    var fullName: String          { "\(firstNames) \(lastNames)".trimmed }
    var phoneNumber: String?      { telefono?.trimmed.isNotBlank == true ? telefono : nil }
    var emailValue: String?       { correo?.trimmed.isNotBlank == true ? correo : nil }
    var addressValue: String?     { direccion?.trimmed.isNotBlank == true ? direccion : nil }
    var statusValue: String       { estado ?? "Activo" }
    var registrationDate: Date    { fechaRegistro ?? Date() }
    var isActive: Bool            { statusValue == "Activo" }

    var latitude: Double           { ubicacion?.latitude  ?? 0 }
    var longitude: Double          { ubicacion?.longitude ?? 0 }
    var hasValidCoordinates: Bool  { ubicacion?.hasValidCoordinates ?? false }
    var locationReference: String? { ubicacion?.reference }

    var ventasArray: [Venta] {
        (ventas?.allObjects as? [Venta] ?? [])
            .sorted { ($0.fechaVenta ?? Date()) > ($1.fechaVenta ?? Date()) }
    }

    // MARK: Fetch Requests

    static func all(onlyActive: Bool = false) -> NSFetchRequest<Cliente> {
        let req = fetchRequest()
        req.predicate = onlyActive
            ? NSPredicate(format: "estado == %@", "Activo")
            : nil
        req.sortDescriptors = [NSSortDescriptor(key: "apellidos", ascending: true,
                                                 selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        return req
    }

    static func byDNI(_ dni: String) -> NSFetchRequest<Cliente> {
        let req = fetchRequest()
        req.predicate  = NSPredicate(format: "dni == %@", dni)
        req.fetchLimit = 1
        return req
    }

    static func byID(_ id: UUID) -> NSFetchRequest<Cliente> {
        let req = fetchRequest()
        req.predicate  = NSPredicate(format: "idCliente == %@", id as CVarArg)
        req.fetchLimit = 1
        return req
    }

    static func search(text: String, onlyActive: Bool = false) -> NSFetchRequest<Cliente> {
        let req = fetchRequest()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "nombres CONTAINS[cd] %@ OR apellidos CONTAINS[cd] %@ OR dni CONTAINS[cd] %@",
                        text, text, text)
        ]
        if onlyActive {
            predicates.append(NSPredicate(format: "estado == %@", "Activo"))
        }
        req.predicate       = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        req.sortDescriptors = [NSSortDescriptor(key: "apellidos", ascending: true)]
        return req
    }
}

// ══════════════════════════════════════════════════════════
// MARK: - Ubicacion
// ══════════════════════════════════════════════════════════

@objc(Ubicacion)
public class Ubicacion: NSManagedObject {}

extension Ubicacion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ubicacion> {
        NSFetchRequest<Ubicacion>(entityName: "Ubicacion")
    }

    // MARK: Attributes
    @NSManaged public var idUbicacion:         UUID?
    @NSManaged public var latitud:             NSDecimalNumber?
    @NSManaged public var longitud:            NSDecimalNumber?
    @NSManaged public var direccionReferencia: String?
    @NSManaged public var fechaRegistro:       Date?

    // MARK: Relationships
    @NSManaged public var cliente: Cliente?    // → Cliente (to-one, nullify)
}

extension Ubicacion: Identifiable {
    public var id: UUID { idUbicacion ?? UUID() }
}

extension Ubicacion {

    var latitude: Double   { latitud?.doubleValue  ?? 0 }
    var longitude: Double  { longitud?.doubleValue ?? 0 }
    var reference: String? { direccionReferencia?.trimmed.isNotBlank == true ? direccionReferencia : nil }
    var registrationDate: Date { fechaRegistro ?? Date() }
    var hasValidCoordinates: Bool { latitude != 0 || longitude != 0 }
}

// ══════════════════════════════════════════════════════════
// MARK: - Venta
// ══════════════════════════════════════════════════════════

@objc(Venta)
public class Venta: NSManagedObject {}

extension Venta {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Venta> {
        NSFetchRequest<Venta>(entityName: "Venta")
    }

    // MARK: Attributes
    @NSManaged public var idVenta:    UUID?
    @NSManaged public var fechaVenta: Date?
    @NSManaged public var subtotal:   NSDecimalNumber?
    @NSManaged public var igv:        NSDecimalNumber?
    @NSManaged public var total:      NSDecimalNumber?
    @NSManaged public var estado:     String?

    // MARK: Relationships
    @NSManaged public var cliente:  Cliente?       // → Cliente (to-one, nullify)
    @NSManaged public var usuario:  Usuario?       // → Usuario (to-one, nullify)
    @NSManaged public var detalles: NSSet?         // → [DetalleVenta] (to-many, cascade)

    // MARK: to-many Accessors
    @objc(addDetallesObject:)    @NSManaged public func addToDetalles(_ value: DetalleVenta)
    @objc(removeDetallesObject:) @NSManaged public func removeFromDetalles(_ value: DetalleVenta)
    @objc(addDetalles:)          @NSManaged public func addToDetalles(_ values: NSSet)
    @objc(removeDetalles:)       @NSManaged public func removeFromDetalles(_ values: NSSet)
}

extension Venta: Identifiable {
    public var id: UUID { idVenta ?? UUID() }
}

extension Venta {

    var saleDate: Date           { fechaVenta ?? Date() }
    var subtotalDecimal: Decimal { subtotal?.decimalValue ?? 0 }
    var igvDecimal: Decimal      { igv?.decimalValue ?? 0 }
    var totalDecimal: Decimal    { total?.decimalValue ?? 0 }
    var subtotalDouble: Double   { subtotal?.doubleValue ?? 0 }
    var totalDouble: Double      { total?.doubleValue  ?? 0 }
    var statusValue: String      { estado ?? "Completada" }
    var clientName: String       { cliente?.fullName ?? "Sin cliente" }
    var sellerName: String       { usuario?.fullName ?? "Sin vendedor" }

    var detallesArray: [DetalleVenta] {
        (detalles?.allObjects as? [DetalleVenta] ?? [])
            .sorted { $0.productName < $1.productName }
    }

    // MARK: Fetch Requests

    static func all() -> NSFetchRequest<Venta> {
        let req = fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "fechaVenta", ascending: false)]
        return req
    }

    static func byID(_ id: UUID) -> NSFetchRequest<Venta> {
        let req = fetchRequest()
        req.predicate  = NSPredicate(format: "idVenta == %@", id as CVarArg)
        req.fetchLimit = 1
        return req
    }

    static func byDateRange(from start: Date, to end: Date) -> NSFetchRequest<Venta> {
        let req = fetchRequest()
        req.predicate = NSPredicate(format: "fechaVenta >= %@ AND fechaVenta <= %@",
                                    start as CVarArg, end as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "fechaVenta", ascending: false)]
        return req
    }

    static func search(text: String) -> NSFetchRequest<Venta> {
        let req = fetchRequest()
        req.predicate = NSPredicate(
            format: "cliente.nombres CONTAINS[cd] %@ OR cliente.apellidos CONTAINS[cd] %@ OR cliente.dni CONTAINS[cd] %@",
            text, text, text
        )
        req.sortDescriptors = [NSSortDescriptor(key: "fechaVenta", ascending: false)]
        return req
    }

    /// All ventas for a specific client, newest first.
    static func byClient(_ clientID: UUID) -> NSFetchRequest<Venta> {
        let req = fetchRequest()
        req.predicate       = NSPredicate(format: "cliente.idCliente == %@", clientID as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "fechaVenta", ascending: false)]
        return req
    }

    /// The single most recent venta.
    static func mostRecent() -> NSFetchRequest<Venta> {
        let req = fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "fechaVenta", ascending: false)]
        req.fetchLimit      = 1
        return req
    }
}

// ══════════════════════════════════════════════════════════
// MARK: - DetalleVenta
// ══════════════════════════════════════════════════════════

@objc(DetalleVenta)
public class DetalleVenta: NSManagedObject {}

extension DetalleVenta {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DetalleVenta> {
        NSFetchRequest<DetalleVenta>(entityName: "DetalleVenta")
    }

    // MARK: Attributes
    @NSManaged public var idDetalleVenta:  UUID?
    @NSManaged public var cantidad:        Int32              // usesScalarValueType = YES
    @NSManaged public var precioUnitario:  NSDecimalNumber?
    @NSManaged public var subtotalLinea:   NSDecimalNumber?

    // MARK: Relationships
    @NSManaged public var venta:    Venta?     // → Venta    (to-one, nullify)
    @NSManaged public var producto: Producto?  // → Producto (to-one, nullify)
}

extension DetalleVenta: Identifiable {
    public var id: UUID { idDetalleVenta ?? UUID() }
}

extension DetalleVenta {

    var quantityInt: Int         { Int(cantidad) }
    var unitPrice: Decimal       { precioUnitario?.decimalValue ?? 0 }
    var lineTotal: Decimal       { subtotalLinea?.decimalValue  ?? 0 }
    var unitPriceDouble: Double  { precioUnitario?.doubleValue  ?? 0 }
    var lineTotalDouble: Double  { subtotalLinea?.doubleValue   ?? 0 }
    var productName: String      { producto?.productName   ?? "Sin producto" }
    var productCode: String      { producto?.productCode   ?? "" }
    var productCategory: String  { producto?.categoryValue ?? "" }
}
