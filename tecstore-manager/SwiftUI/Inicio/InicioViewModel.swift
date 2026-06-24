import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - InicioViewModel
// ─────────────────────────────────────────────

@MainActor
final class InicioViewModel: ObservableObject {

    @Published var todaySalesCount:  Int     = 0
    @Published var todaySalesTotal:  Double  = 0
    @Published var outOfStockCount:  Int     = 0
    @Published var totalClients:     Int     = 0
    @Published var userName:         String? = nil

    func loadMetrics() {
        let t           = ReporteService.shared.todayMetrics()
        todaySalesCount = t.count
        todaySalesTotal = t.total
        outOfStockCount = ReporteService.shared.countOutOfStock()
        totalClients    = ReporteService.shared.countClientes()
        userName        = AuthService.shared.currentUser?.fullName
    }
}
