import Foundation

final class ListaClientesViewModel {

    // MARK: - Outputs

    var onReload: (() -> Void)?
    var onEmptyStateChanged: ((Bool) -> Void)?
    var onFilterActiveChanged: ((Bool) -> Void)?

    // MARK: - State

    private(set) var filteredClientes: [Cliente] = []
    private(set) var activeFilter: Int = 0
    private var allClientes: [Cliente] = []
    private var currentSearchText = ""

    // MARK: - Inputs

    func loadData() {
        allClientes = ClienteService.shared.fetchAll()
        applyFilters(searchText: currentSearchText)
    }

    func applyFilters(searchText: String) {
        currentSearchText = searchText
        var result = searchText.isEmpty ? allClientes : allClientes.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) || $0.dniValue.contains(searchText)
        }
        switch activeFilter {
        case 1: result = result.filter {  $0.isActive }
        case 2: result = result.filter { !$0.isActive }
        default: break
        }
        filteredClientes = result
        onReload?()
        onEmptyStateChanged?(filteredClientes.isEmpty)
    }

    func setFilter(_ index: Int) {
        activeFilter = index
        onFilterActiveChanged?(index != 0)
        applyFilters(searchText: currentSearchText)
    }

    func deleteCliente(_ cliente: Cliente) {
        ClienteService.shared.delete(cliente)
        loadData()
    }
}
