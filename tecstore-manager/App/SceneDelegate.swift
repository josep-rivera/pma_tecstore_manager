import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - Scene Connection

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Seed initial data on first launch
        SeederService.shared.seedIfNeeded()

        // Configure global UIKit appearance
        AppStyle.configureGlobalAppearance()

        // Build window
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.rootViewController = makeRootViewController()
        window.makeKeyAndVisible()

        // Apply saved dark mode preference
        applyStoredAppearance()

        // Listen for logout events posted from SwiftUI screens
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogout),
            name: .userDidLogout,
            object: nil
        )
    }

    // MARK: - Root View Controller

    private func makeRootViewController() -> UIViewController {
        AuthService.shared.hasActiveSession
            ? makeMenuViewController()
            : makeAuthNavigationController()
    }

    // Auth flow: UINavigationController → UIHostingController<BienvenidaView>
    func makeAuthNavigationController() -> UINavigationController {
        let bienvenidaView = BienvenidaView(
            onLogin:    { [weak self] in self?.pushLogin() },
            onRegister: { [weak self] in self?.pushRegister() }
        )
        let hostingVC = UIHostingController(rootView: bienvenidaView)
        hostingVC.view.backgroundColor = .appBackground

        let nav = UINavigationController(rootViewController: hostingVC)
        nav.setNavigationBarHidden(true, animated: false)
        return nav
    }

    // Main app flow: MenuViewController (UITabBarController)
    func makeMenuViewController() -> UIViewController {
        MenuViewController()
    }

    // MARK: - Auth Navigation (called from BienvenidaView closures)

    func pushLogin() {
        guard let nav = window?.rootViewController as? UINavigationController else { return }
        let loginVC = LoginViewController()
        loginVC.onLoginSuccess  = { [weak self] in self?.transitionToMenu() }
        loginVC.onGoToRegister  = { [weak self] in self?.pushRegister() }
        nav.pushViewController(loginVC, animated: true)
    }

    func pushRegister() {
        guard let nav = window?.rootViewController as? UINavigationController else { return }

        // Avoid pushing duplicates
        if nav.viewControllers.contains(where: { $0 is RegistroViewController }) {
            nav.popToRootViewController(animated: true)
            return
        }

        let registerVC = RegistroViewController()
        registerVC.onRegisterSuccess = { [weak self] in self?.transitionToMenu() }
        registerVC.onGoToLogin       = { [weak nav]  in nav?.popToRootViewController(animated: true) }
        nav.pushViewController(registerVC, animated: true)
    }

    // MARK: - Transitions

    /// Replace root with MenuViewController (after login or register)
    func transitionToMenu() {
        guard let window else { return }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = self.makeMenuViewController()
        }
    }

    /// Replace root with auth flow (after logout)
    func transitionToAuth() {
        guard let window else { return }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = self.makeAuthNavigationController()
        }
    }

    // MARK: - Dark Mode

    /// Apply and persist dark mode preference immediately
    func setDarkMode(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.darkModeEnabled)
        window?.overrideUserInterfaceStyle = enabled ? .dark : .light
    }

    private func applyStoredAppearance() {
        let isDark = UserDefaults.standard.bool(forKey: UserDefaultsKeys.darkModeEnabled)
        window?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }

    // MARK: - Notification Handlers

    @objc private func handleLogout() {
        transitionToAuth()
    }

    // MARK: - Static Accessor

    /// Access SceneDelegate from anywhere in the app (useful from SwiftUI)
    static var shared: SceneDelegate? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.delegate as? SceneDelegate
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidLogout    = Notification.Name("userDidLogout")
    static let darkModeChanged  = Notification.Name("darkModeChanged")
}

// MARK: - UserDefaults Keys

enum UserDefaultsKeys {
    static let darkModeEnabled  = "darkModeEnabled"
    static let activeUserID     = "activeUserID"
}
