import UIKit
import SwiftUI

final class MenuViewController: UITabBarController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }

    // MARK: - Tab Setup

    private func setupTabs() {
        viewControllers = [
            makeInicioTab(),
            makeProductosTab(),
            makeClientesTab(),
            makeVentasTab(),
            makePerfilTab()
        ]
    }

    // ── Tab 1: Inicio (SwiftUI – InicioView with its own NavigationStack)
    private func makeInicioTab() -> UIViewController {
        let vc = UIHostingController(rootView: InicioView())
        vc.tabBarItem = UITabBarItem(
            title: "Inicio",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        return vc
    }

    // ── Tab 2: Productos (UIKit – UINavigationController → ListaProductosViewController)
    private func makeProductosTab() -> UIViewController {
        let nav = UINavigationController(rootViewController: ListaProductosViewController())
        nav.tabBarItem = UITabBarItem(
            title: "Productos",
            image: UIImage(systemName: "shippingbox"),
            selectedImage: UIImage(systemName: "shippingbox.fill")
        )
        forceOpaqueNavBar(nav)
        return nav
    }

    // ── Tab 3: Clientes (UIKit – UINavigationController → ListaClientesViewController)
    private func makeClientesTab() -> UIViewController {
        let nav = UINavigationController(rootViewController: ListaClientesViewController())
        nav.tabBarItem = UITabBarItem(
            title: "Clientes",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )
        forceOpaqueNavBar(nav)
        return nav
    }

    private func forceOpaqueNavBar(_ nav: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBackground
        appearance.shadowColor     = .appSeparator
        appearance.titleTextAttributes = [
            .font:            AppFont.headline(),
            .foregroundColor: UIColor.appTextPrimary
        ]
        nav.navigationBar.standardAppearance          = appearance
        nav.navigationBar.scrollEdgeAppearance        = appearance
        nav.navigationBar.compactAppearance           = appearance
        nav.navigationBar.compactScrollEdgeAppearance = appearance
        nav.navigationBar.tintColor                   = .brandPrimary
    }

    // ── Tab 4: Ventas (SwiftUI – ListaVentasView manages its own NavigationStack)
    private func makeVentasTab() -> UIViewController {
        let vc = UIHostingController(rootView: ListaVentasView())
        vc.tabBarItem = UITabBarItem(
            title: "Ventas",
            image: UIImage(systemName: "cart"),
            selectedImage: UIImage(systemName: "cart.fill")
        )
        return vc
    }

    // ── Tab 5: Perfil (SwiftUI – PerfilView manages its own NavigationStack)
    private func makePerfilTab() -> UIViewController {
        let vc = UIHostingController(rootView: PerfilView())
        vc.tabBarItem = UITabBarItem(
            title: "Perfil",
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )
        return vc
    }
}
