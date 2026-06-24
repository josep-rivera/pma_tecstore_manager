import Foundation

final class DetalleClienteViewModel {

    // MARK: - Outputs

    var onClienteUpdated: ((Cliente) -> Void)?

    // MARK: - Inputs

    func refresh(clienteID: UUID) {
        if let updated = ClienteService.shared.fetch(byID: clienteID) {
            onClienteUpdated?(updated)
        }
    }
}
