import SwiftUI
import Combine
import MapKit

// ════════════════════════════════════════════════════════════
// MARK: - BusquedasViewModel
// ════════════════════════════════════════════════════════════

@MainActor
final class BusquedasViewModel: ObservableObject {

    enum Segment: Int, CaseIterable {
        case productos = 0, clientes = 1, ventas = 2
        var title: String {
            switch self { case .productos: "Productos"; case .clientes: "Clientes"; case .ventas: "Ventas" }
        }
    }

    enum ProductoFilter: Int, CaseIterable {
        case todos, conStock, sinStock
        var title: String {
            switch self { case .todos: "Todos"; case .conStock: "Con stock"; case .sinStock: "Sin stock" }
        }
    }

    enum ClienteFilter: Int, CaseIterable {
        case todos, activos, inactivos
        var title: String {
            switch self { case .todos: "Todos"; case .activos: "Activos"; case .inactivos: "Inactivos" }
        }
    }

    @Published var searchText:       String         = ""
    @Published var selectedSegment:  Segment        = .productos
    @Published var productoFilter:   ProductoFilter = .todos
    @Published var categoriaFilter:  String         = "Todos"
    @Published var clienteFilter:    ClienteFilter  = .todos
    @Published var productos:        [Producto]     = []
    @Published var clientes:         [Cliente]      = []
    @Published var ventas:           [Venta]        = []

    // Venta date + amount filter
    @Published var ventaStartDate:  Date   = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var ventaEndDate:    Date   = Date()
    @Published var ventaMinAmount:  String = ""

    // Detail sheets
    @Published var selectedProducto: Producto? = nil
    @Published var selectedCliente:  Cliente?  = nil
    @Published var selectedVenta:    Venta?    = nil

    func search() {
        let text = searchText.trimmed.lowercased()
        switch selectedSegment {
        case .productos:
            var result = ProductoService.shared.fetchAll()
            if !text.isEmpty {
                result = result.filter {
                    $0.productName.lowercased().contains(text) ||
                    $0.productCode.lowercased().contains(text) ||
                    $0.categoryValue.lowercased().contains(text)
                }
            }
            switch productoFilter {
            case .conStock:  result = result.filter { $0.hasStock }
            case .sinStock:  result = result.filter { !$0.hasStock }
            case .todos:     break
            }
            if self.categoriaFilter != "Todos" {
                result = result.filter { $0.categoryValue == self.categoriaFilter }
            }
            productos = result

        case .clientes:
            var result = ClienteService.shared.fetchAll()
            if !text.isEmpty {
                result = result.filter {
                    $0.firstNames.lowercased().contains(text) ||
                    $0.lastNames.lowercased().contains(text) ||
                    $0.dniValue.contains(text) ||
                    ($0.emailValue?.lowercased().contains(text) ?? false)
                }
            }
            switch clienteFilter {
            case .activos:   result = result.filter { $0.isActive }
            case .inactivos: result = result.filter { !$0.isActive }
            case .todos:     break
            }
            clientes = result

        case .ventas:
            ventas = fetchVentas(from: ventaStartDate, to: ventaEndDate,
                                 minAmount: ventaMinAmount, searchText: text)
        }
    }

    var hasActiveFilters: Bool {
        switch selectedSegment {
        case .productos:
            return productoFilter != .todos || categoriaFilter != "Todos"
        case .clientes:
            return clienteFilter != .todos
        case .ventas:
            return ventaMinAmount.isNotBlank
        }
    }

    func resetFilters() {
        productoFilter  = .todos
        categoriaFilter = "Todos"
        clienteFilter   = .todos
        ventaMinAmount  = ""
        ventaStartDate  = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        ventaEndDate    = Date()
    }

    func applyVentaDateFilter() {
        ventas = fetchVentas(from: ventaStartDate, to: ventaEndDate,
                             minAmount: ventaMinAmount, searchText: "")
    }

    private func fetchVentas(from start: Date, to end: Date,
                             minAmount: String, searchText: String) -> [Venta] {
        var result = VentaService.shared.fetch(from: start, to: end)
        if !searchText.isEmpty {
            result = result.filter {
                $0.clientName.lowercased().contains(searchText) ||
                ($0.cliente?.dniValue ?? "").contains(searchText) ||
                $0.sellerName.lowercased().contains(searchText)
            }
        }
        if let min = Double(minAmount), min > 0 {
            result = result.filter { $0.totalDouble >= min }
        }
        return result
    }
}
