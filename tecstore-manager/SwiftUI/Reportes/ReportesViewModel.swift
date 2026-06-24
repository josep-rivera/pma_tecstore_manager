import SwiftUI
import Charts
import Combine

// ─────────────────────────────────────────────
// MARK: - ReportesViewModel
// ─────────────────────────────────────────────

@MainActor
final class ReportesViewModel: ObservableObject {

    @Published var report:          ReporteData? = nil
    @Published var byCategory:      [(category: String, total: Double)] = []
    @Published var topProductos:    [(name: String, revenue: Double)]   = []
    @Published var weeklyTrend:     [(date: Date, count: Int)]          = []
    @Published var isLoading:       Bool = false

    func loadReport() {
        isLoading    = true
        report       = ReporteService.shared.generateReport()
        byCategory   = ReporteService.shared.revenueByCategory()
        topProductos = ReporteService.shared.topProductosByRevenue(limit: AppConstants.topProductosLimit)
        weeklyTrend  = ReporteService.shared.salesByDay(lastDays: AppConstants.salesTrendWindowDays)
        isLoading    = false
    }
}
