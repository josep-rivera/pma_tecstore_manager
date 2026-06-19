import UIKit

final class LoginViewController: UIViewController {

    // MARK: - Navigation Callbacks
    var onLoginSuccess: (() -> Void)?
    var onGoToRegister: (() -> Void)?

    // MARK: - UI Elements
    private let scrollView   = UIScrollView()
    private let contentView  = UIView()

    private let logoBackground: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor    = UIColor.brandPrimary.withAlphaComponent(0.10)
        v.layer.cornerRadius = 50
        return v
    }()
    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "storefront.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor    = .brandPrimary
        iv.contentMode  = .scaleAspectFit
        return iv
    }()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = "TecStore Manager"
        l.font          = AppFont.title1()
        l.textColor     = .appTextPrimary
        l.textAlignment = .center
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = "Inicia sesión para continuar"
        l.font          = AppFont.body()
        l.textColor     = .appTextSecondary
        l.textAlignment = .center
        return l
    }()

    private let correoField   = UITextField()
    private let correoError   = AppStyle.makeErrorLabel()
    private let passwordField = UITextField()
    private let passwordError = AppStyle.makeErrorLabel()
    private let loginButton   = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)

    private let seedCredentialsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font          = AppFont.caption1()
        l.textColor     = .appTextTertiary
        l.text          = "Cuentas de prueba\nana.garcia@tecsup.edu.pe  •  123456\ncarlos.mendoza@tecsup.edu.pe  •  123456"
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScrollView()
        setupFields()
        setupButtons()
        setupConstraints()
        setupKeyboard()
        _ = validate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        view.addSubview(seedCredentialsLabel)
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(logoBackground, logoImageView, titleLabel, subtitleLabel,
                                correoField, correoError,
                                passwordField, passwordError,
                                loginButton, registerButton)
    }

    private func setupFields() {
        AppStyle.style(textField: correoField,
                       placeholder: "Correo electrónico",
                       icon: "envelope",
                       keyboardType: .emailAddress,
                       returnKey: .next)
        correoField.translatesAutoresizingMaskIntoConstraints = false
        correoField.delegate = self
        correoField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)

        AppStyle.style(textField: passwordField,
                       placeholder: "Contraseña",
                       icon: "lock",
                       isSecure: true,
                       returnKey: .done)
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.delegate = self
        passwordField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
    }

    private func setupButtons() {
        AppStyle.applyPrimary(to: loginButton, title: "Iniciar sesión")
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)

        AppStyle.applyText(to: registerButton, title: "¿No tienes cuenta? Regístrate")
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.addTarget(self, action: #selector(handleGoToRegister), for: .touchUpInside)
    }

    private func setupConstraints() {
        let p = AppLayout.padding
        let ph = AppLayout.paddingLarge
        let fh = AppLayout.textFieldHeight

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            logoBackground.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 48),
            logoBackground.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoBackground.widthAnchor.constraint(equalToConstant: 100),
            logoBackground.heightAnchor.constraint(equalToConstant: 100),
            logoImageView.centerXAnchor.constraint(equalTo: logoBackground.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoBackground.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 44),
            logoImageView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: logoBackground.bottomAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            correoField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 44),
            correoField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            correoField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            correoField.heightAnchor.constraint(equalToConstant: fh),

            correoError.topAnchor.constraint(equalTo: correoField.bottomAnchor, constant: 4),
            correoError.leadingAnchor.constraint(equalTo: correoField.leadingAnchor),
            correoError.trailingAnchor.constraint(equalTo: correoField.trailingAnchor),

            passwordField.topAnchor.constraint(equalTo: correoError.bottomAnchor, constant: p),
            passwordField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            passwordField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            passwordField.heightAnchor.constraint(equalToConstant: fh),

            passwordError.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 4),
            passwordError.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor),
            passwordError.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),

            loginButton.topAnchor.constraint(equalTo: passwordError.bottomAnchor, constant: 36),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            loginButton.heightAnchor.constraint(equalToConstant: AppLayout.buttonHeight),

            registerButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: p),
            registerButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            registerButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -48),

            seedCredentialsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ph),
            seedCredentialsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ph),
            seedCredentialsLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Actions

    @objc private func handleLogin() {
        guard validate() else { return }
        do {
            try AuthService.shared.login(
                email:    correoField.text ?? "",
                password: passwordField.text ?? ""
            )
            onLoginSuccess?()
        } catch let error as ServiceError {
            showAlert(title: "Error al iniciar sesión",
                      message: error.errorDescription ?? "")
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    @objc private func handleGoToRegister() { onGoToRegister?() }
    @objc private func fieldsChanged()       { _ = validate() }
    @objc private func tapToDismiss()     { view.endEditing(true) }

    @objc private func keyboardWillShow(_ n: NSNotification) {
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            scrollView.contentInset.bottom                    = frame.height + 20
            scrollView.verticalScrollIndicatorInsets.bottom   = frame.height
        }
    }
    @objc private func keyboardWillHide(_ n: NSNotification) {
        scrollView.contentInset.bottom                  = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: - Validation

    @discardableResult
    private func validate() -> Bool {
        var valid = true

        let correo = correoField.text?.trimmed ?? ""
        if correo.isEmpty {
            setError(correoError, correoField, "El correo es requerido.")
            valid = false
        } else if !correo.isValidEmail {
            setError(correoError, correoField, "Formato de correo inválido.")
            valid = false
        } else {
            clearError(correoError, correoField)
        }

        let pwd = passwordField.text ?? ""
        if pwd.isEmpty {
            setError(passwordError, passwordField, "La contraseña es requerida.")
            valid = false
        } else if pwd.count < 6 {
            setError(passwordError, passwordField, "Mínimo 6 caracteres.")
            valid = false
        } else {
            clearError(passwordError, passwordField)
        }

        loginButton.isEnabled = valid
        loginButton.alpha     = valid ? 1 : 0.6
        return valid
    }

    private func setError(_ label: UILabel, _ field: UITextField, _ msg: String) {
        label.text     = msg
        label.isHidden = false
        AppStyle.markFieldError(field, hasError: true)
    }
    private func clearError(_ label: UILabel, _ field: UITextField) {
        label.isHidden = true
        AppStyle.markFieldError(field, hasError: false)
    }
}

// MARK: - UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == correoField { passwordField.becomeFirstResponder() }
        else { textField.resignFirstResponder(); handleLogin() }
        return true
    }
}
