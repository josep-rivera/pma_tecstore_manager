import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - StockBajoViewModel
// ─────────────────────────────────────────────

@MainActor
final class StockBajoViewModel: ObservableObject {

    @Published var productos: [Producto] = []
    @Published var isLoading: Bool = false

    func loadProductos() {
        guard !isLoading else { return }
        isLoading = true
        productos = ProductoService.shared.fetchLowStock(threshold: Int32(AppConstants.lowStockThreshold))
        isLoading = false
    }
}
