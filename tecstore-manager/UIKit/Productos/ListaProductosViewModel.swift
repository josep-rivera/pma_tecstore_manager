import Foundation

final class ListaProductosViewModel {

    // MARK: - Outputs

    var onReload: (() -> Void)?
    var onEmptyStateChanged: ((Bool) -> Void)?

    // MARK: - State

    private(set) var filteredProductos: [Producto] = []
    private(set) var activeFilter: Int = 0
    private var allProductos: [Producto] = []
    private var currentSearchText = ""

    // MARK: - Inputs

    func loadData() {
        allProductos = ProductoService.shared.fetchAll()
        applyFilters(searchText: currentSearchText)
    }

    func applyFilters(searchText: String) {
        currentSearchText = searchText
        var result = searchText.isEmpty ? allProductos : allProductos.filter {
            $0.productName.localizedCaseInsensitiveContains(searchText) ||
            $0.productCode.localizedCaseInsensitiveContains(searchText) ||
            $0.categoryValue.localizedCaseInsensitiveContains(searchText)
        }
        switch activeFilter {
        case 1: result = result.filter {  $0.hasStock }
        case 2: result = result.filter { !$0.hasStock }
        default: break
        }
        filteredProductos = result
        onReload?()
        onEmptyStateChanged?(filteredProductos.isEmpty)
    }

    func setFilter(_ index: Int) {
        activeFilter = index
        applyFilters(searchText: currentSearchText)
    }

    func deleteProducto(_ producto: Producto) {
        ProductoService.shared.delete(producto)
        loadData()
    }
}
