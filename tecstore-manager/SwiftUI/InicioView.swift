import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - InicioViewModel
// ─────────────────────────────────────────────

@MainActor
final class InicioViewModel: ObservableObject {

    @Published var todaySalesCount:  Int    = 0
    @Published var todaySalesTotal:  Double = 0
    @Published var outOfStockCount:  Int    = 0
    @Published var totalClientes:    Int    = 0

    func loadMetrics() {
        let today        = ReporteService.shared.todayMetrics()
        todaySalesCount  = today.count
        todaySalesTotal  = today.total
        outOfStockCount  = ReporteService.shared.countOutOfStock()
        totalClientes    = ReporteService.shared.countClientes()
    }
}

// ─────────────────────────────────────────────
// MARK: - InicioView
// ─────────────────────────────────────────────

struct InicioView: View {

    @StateObject private var viewModel = InicioViewModel()
    @State private var showNewSale     = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CGFloat(AppLayout.paddingLarge)) {

                    welcomeHeader

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: CGFloat(AppLayout.padding)
                    ) {
                        MetricCard(icon: "cart.fill",   color: .brandPrimary,
                                   value: "\(viewModel.todaySalesCount)", label: "Ventas hoy")
                        MetricCard(icon: "banknote.fill", color: Color.appSuccess,
                                   value: viewModel.todaySalesTotal.asCurrency, label: "Ingresos hoy")
                        MetricCard(icon: "exclamationmark.triangle.fill", color: Color.appWarning,
                                   value: "\(viewModel.outOfStockCount)", label: "Sin stock")
                        MetricCard(icon: "person.2.fill", color: Color(UIColor.systemIndigo),
                                   value: "\(viewModel.totalClientes)", label: "Clientes")
                    }
                    .padding(.horizontal, CGFloat(AppLayout.padding))

                    shortcutsSection
                }
                .padding(.vertical, CGFloat(AppLayout.padding))
            }
            .background(Color(UIColor.appGrouped))
            .navigationTitle("Inicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { viewModel.loadMetrics() }
            .sheet(isPresented: $showNewSale) {
                NavigationStack {
                    RegistroVentaView(onSave: { showNewSale = false }, isModal: true)
                }
            }
        }
    }

    // ── Welcome ──
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bienvenido")
                    .font(.system(.title2, design: .serif).bold())
                if let name = AuthService.shared.currentUser?.fullName {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "storefront.fill")
                .font(.system(.title, design: .serif))
                .foregroundColor(.brandPrimary)
        }
        .padding(CGFloat(AppLayout.paddingLarge))
        .background(Color(UIColor.systemBackground))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, CGFloat(AppLayout.padding))
    }

    // ── Shortcuts ──
    private var shortcutsSection: some View {
        VStack(spacing: CGFloat(AppLayout.paddingSmall)) {
            Text("Accesos rápidos")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CGFloat(AppLayout.padding))

            NavigationLink(destination: BusquedasView()) {
                ShortcutCard(icon: "magnifyingglass", title: "Búsquedas",
                             subtitle: "Buscar en productos, clientes y ventas",
                             color: .brandPrimary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))

            NavigationLink(destination: ReportesView()) {
                ShortcutCard(icon: "chart.bar.fill", title: "Reportes",
                             subtitle: "Métricas y tendencias de la tienda",
                             color: Color.appSuccess)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))

            Button { showNewSale = true } label: {
                ShortcutCard(icon: "cart.badge.plus", title: "Nueva venta",
                             subtitle: "Registrar una venta rápidamente",
                             color: Color(UIColor.systemOrange))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))

            NavigationLink(destination: StockBajoView()) {
                ShortcutCard(icon: "exclamationmark.triangle.fill", title: "Stock bajo",
                             subtitle: "Productos con 5 unidades o menos",
                             color: Color.appWarning)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - StockBajoView
// ─────────────────────────────────────────────

struct StockBajoView: View {

    @State private var productos: [Producto] = []

    var body: some View {
        Group {
            if productos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.appSuccess)
                    Text("Todos los productos tienen stock suficiente")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(productos) { p in
                    HStack(spacing: 12) {
                        Image(systemName: p.categoryEnum.icon)
                            .font(.system(.title3, design: .serif))
                            .foregroundColor(Color(UIColor.colorForCategory(p.categoryValue)))
                            .frame(width: 36, height: 36)
                            .background(Color(UIColor.colorForCategory(p.categoryValue)).opacity(0.12))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.productName).font(.subheadline.weight(.medium))
                            Text(p.productCode).font(.caption).foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("\(p.stockInt) ud.")
                                .font(.subheadline.bold())
                                .foregroundColor(Color(p.stockInt.stockUIColor))
                            Text(p.stockInt.stockLabel)
                                .font(.caption2)
                                .foregroundColor(Color(p.stockInt.stockUIColor))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Stock bajo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            productos = ProductoService.shared.fetchAll()
                .filter { $0.isActive && $0.stockInt <= 5 }
                .sorted { $0.stockInt < $1.stockInt }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Reusable Card Components
// ─────────────────────────────────────────────

struct MetricCard: View {
    let icon:   String
    let color:  Color
    let value:  String
    let label:  String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(.title3, design: .serif))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(.title2, design: .serif).bold())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.systemBackground))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct ShortcutCard: View {
    let icon:     String
    let title:    String
    let subtitle: String
    let color:    Color

    var body: some View {
        HStack(spacing: CGFloat(AppLayout.padding)) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(.title3, design: .serif))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(UIColor.appTextTertiary))
        }
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.systemBackground))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}
