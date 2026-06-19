import UIKit
import SwiftUI

final class MenuViewController: UITabBarController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Tab viewControllers are set up via storyboard relationship segues.
        // Apply nav bar appearance to UIKit tab nav controllers.
        applyNavBarAppearance()
    }

    // MARK: - Appearance

    private func applyNavBarAppearance() {
        for vc in viewControllers ?? [] {
            guard let nav = vc as? UINavigationController else { continue }
            forceOpaqueNavBar(nav)
        }
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
}
