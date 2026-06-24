import Foundation

final class DetalleProductoViewModel {

    // MARK: - Outputs

    var onProductoUpdated: ((Producto) -> Void)?

    // MARK: - Inputs

    func refresh(productoID: UUID) {
        if let updated = ProductoService.shared.fetch(byID: productoID) {
            onProductoUpdated?(updated)
        }
    }
}
