import UIKit
import SwiftUI

// MARK: - InicioHostingController

final class InicioHostingController: UIHostingController<InicioView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: InicioView())
    }
}

// MARK: - VentasHostingController

final class VentasHostingController: UIHostingController<ListaVentasView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: ListaVentasView())
    }
}

// MARK: - PerfilHostingController

final class PerfilHostingController: UIHostingController<PerfilView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: PerfilView())
    }
}

// MARK: - BusquedasHostingController

final class BusquedasHostingController: UIHostingController<BusquedasView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: BusquedasView())
    }
}

// MARK: - ReportesHostingController

final class ReportesHostingController: UIHostingController<ReportesView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: ReportesView())
    }
}

// MARK: - BienvenidaHostingController
// BienvenidaView requires onLogin and onRegister callbacks.
// When loaded from the storyboard, navigation is handled by SceneDelegate.

final class BienvenidaHostingController: UIHostingController<BienvenidaView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: BienvenidaView(
            onLogin: {},
            onRegister: {}
        ))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Rewire callbacks to use SceneDelegate navigation after the controller is loaded.
        rootView = BienvenidaView(
            onLogin: { [weak self] in
                self?.navigationController?.performSegue(withIdentifier: "showLogin", sender: nil)
            },
            onRegister: { [weak self] in
                self?.navigationController?.performSegue(withIdentifier: "showRegistro", sender: nil)
            }
        )
    }
}

// MARK: - RegistroVentaHostingController
// RegistroVentaView requires an onSave callback.
// When used standalone (not modal), dismissing is handled by the navigation stack.

final class RegistroVentaHostingController: UIHostingController<RegistroVentaView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: RegistroVentaView(onSave: {}))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView = RegistroVentaView(onSave: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - DetalleVentaHostingController
// DetalleVentaView requires a Venta object.
// This controller is intended to be used via programmatic push with a Venta injected
// after instantiation. The placeholder guard ensures a safe fallback.

final class DetalleVentaHostingController: UIHostingController<AnyView> {

    var venta: Venta? {
        didSet {
            if let venta {
                rootView = AnyView(DetalleVentaView(venta: venta))
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: AnyView(EmptyView()))
    }
}
