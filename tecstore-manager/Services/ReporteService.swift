import Foundation
import CoreData

// ─────────────────────────────────────────────
// MARK: - ReporteData
// ─────────────────────────────────────────────

/// Snapshot of all dashboard metrics. Created by `ReporteService.generateReport()`.
struct ReporteData {
    let totalVentas:        Int        // 1. Total de ventas registradas
    let montoTotal:         Double     // 2. Monto total vendido (suma de totales)
    let totalClientes:      Int        // 3. Total de clientes registrados
    let totalProductos:     Int        // 4. Total de productos registrados
    let productoMenorStock: Producto?  // 5. Producto con menor stock (activo)
    let ventaMasReciente:   Venta?     // 6. Venta más reciente

    /// True if there is at least one sale in the database.
    var hasSales: Bool { totalVentas > 0 }

    /// Display string for `montoTotal`.
    var montoTotalDisplay: String { montoTotal.asCurrency }
}

// ─────────────────────────────────────────────
// MARK: - ReporteService
// ─────────────────────────────────────────────

final class ReporteService {

    // MARK: Singleton
    static let shared = ReporteService()
    private init() {}

    private let persistence = PersistenceController.shared

    // ─────────────────────────────────────────
    // MARK: - Full Report
    // ─────────────────────────────────────────

    /// Compute all 6 metrics in one call.
    /// Suitable for viewDidAppear / .onAppear refresh.
    func generateReport() -> ReporteData {
        ReporteData(
            totalVentas:        countVentas(),
            montoTotal:         sumMontoTotal(),
            totalClientes:      countClientes(),
            totalProductos:     countProductos(),
            productoMenorStock: fetchProductoMenorStock(),
            ventaMasReciente:   fetchVentaMasReciente()
        )
    }

    // ─────────────────────────────────────────
    // MARK: - Individual Metrics
    // ─────────────────────────────────────────

    /// Total number of Venta records.
    func countVentas() -> Int {
        persistence.count(Venta.all())
    }

    /// Sum of all Venta.total values (as Double for display).
    func sumMontoTotal() -> Double {
        let req = Venta.fetchRequest()
        let ventas = persistence.fetch(req)
        return ventas.reduce(0.0) { $0 + $1.totalDouble }
    }

    /// Total number of Cliente records (active + inactive).
    func countClientes() -> Int {
        persistence.count(Cliente.all())
    }

    /// Total number of Producto records (active + inactive).
    func countProductos() -> Int {
        persistence.count(Producto.all())
    }

    /// The active Producto with the fewest units in stock.
    func fetchProductoMenorStock() -> Producto? {
        persistence.fetch(Producto.lowestStockProduct()).first
    }

    /// The most recently created Venta.
    func fetchVentaMasReciente() -> Venta? {
        persistence.fetch(Venta.mostRecent()).first
    }

    // ─────────────────────────────────────────
    // MARK: - Quick Metrics  (for InicioView cards)
    // ─────────────────────────────────────────

    /// Counts of today's sales and their total amount.
    func todayMetrics() -> (count: Int, total: Double) {
        let today = Date().startOfDay
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let req = Venta.byDateRange(from: today, to: tomorrow)
        let ventas = persistence.fetch(req)
        return (ventas.count, ventas.reduce(0) { $0 + $1.totalDouble })
    }

    /// Number of products whose stock is 0.
    func countOutOfStock() -> Int {
        let req = Producto.fetchRequest()
        req.predicate = NSPredicate(format: "stock == 0 AND estado == %@", "Activo")
        return persistence.count(req)
    }

    /// Total revenue grouped by product category, highest first.
    func revenueByCategory() -> [(category: String, total: Double)] {
        let req = DetalleVenta.fetchRequest()
        let detalles = persistence.fetch(req)
        var dict: [String: Double] = [:]
        for d in detalles { dict[d.productCategory, default: 0] += d.lineTotalDouble }
        let pairs: [(category: String, total: Double)] = dict.map { (category: $0.key, total: $0.value) }
        return pairs.filter { !$0.category.isEmpty }
            .sorted { $0.total > $1.total }
    }

    /// Top products by total revenue.
    func topProductosByRevenue(limit: Int = 3) -> [(name: String, revenue: Double)] {
        let req = DetalleVenta.fetchRequest()
        let detalles = persistence.fetch(req)
        var dict: [String: Double] = [:]
        for d in detalles { dict[d.productName, default: 0] += d.lineTotalDouble }
        let pairs: [(name: String, revenue: Double)] = dict.map { (name: $0.key, revenue: $0.value) }
        return pairs.sorted { $0.revenue > $1.revenue }
            .prefix(limit).map { $0 }
    }

    /// Sales count per day for the last `lastDays` days (oldest → newest).
    func salesByDay(lastDays: Int = 7) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today    = Date().startOfDay
        return (0..<lastDays).reversed().map { offset in
            let day  = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            return (day, persistence.count(Venta.byDateRange(from: day, to: next)))
        }
    }
}

