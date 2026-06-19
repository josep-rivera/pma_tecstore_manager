import UIKit

final class RegistroViewController: UIViewController {

    // MARK: - Navigation Callbacks
    var onRegisterSuccess: (() -> Void)?
    var onGoToLogin: (() -> Void)?

    // MARK: - UI Elements
    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = "Crear cuenta"
        l.font          = AppFont.title1()
        l.textColor     = .appTextPrimary
        l.textAlignment = .center
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = "Completa los datos para registrarte"
        l.font          = AppFont.body()
        l.textColor     = .appTextSecondary
        l.textAlignment = .center
        return l
    }()

    private let nombreField   = UITextField()
    private let nombreError   = AppStyle.makeErrorLabel()
    private let correoField   = UITextField()
    private let correoError   = AppStyle.makeErrorLabel()
    private let passwordField = UITextField()
    private let passwordError = AppStyle.makeErrorLabel()
    private let confirmField  = UITextField()
    private let confirmError  = AppStyle.makeErrorLabel()

    private let registerButton = UIButton(type: .system)
    private let loginButton    = UIButton(type: .system)

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
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(titleLabel, subtitleLabel,
                                nombreField, nombreError,
                                correoField, correoError,
                                passwordField, passwordError,
                                confirmField, confirmError,
                                registerButton, loginButton)
    }

    private func setupFields() {
        let fields: [(UITextField, String, String, UIKeyboardType, UIReturnKeyType, Bool)] = [
            (nombreField,   "Nombre completo",       "person",   .default,      .next, false),
            (correoField,   "Correo electrónico",    "envelope", .emailAddress, .next, false),
            (passwordField, "Contraseña",            "lock",     .default,      .next, true),
            (confirmField,  "Confirmar contraseña",  "lock.fill",.default,      .done, true)
        ]
        for (field, ph, icon, keyboard, returnKey, secure) in fields {
            AppStyle.style(textField: field, placeholder: ph, icon: icon,
                           isSecure: secure, keyboardType: keyboard, returnKey: returnKey)
            field.translatesAutoresizingMaskIntoConstraints = false
            field.delegate = self
            field.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        }
        nombreField.autocapitalizationType = .words
    }

    private func setupButtons() {
        AppStyle.applyPrimary(to: registerButton, title: "Crear cuenta")
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)

        AppStyle.applyText(to: loginButton, title: "¿Ya tienes cuenta? Inicia sesión")
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(handleGoToLogin), for: .touchUpInside)
    }

    private func setupConstraints() {
        let ph = AppLayout.paddingLarge
        let p  = AppLayout.padding
        let fh = AppLayout.textFieldHeight

        let pairs: [(UITextField, UILabel)] = [
            (nombreField, nombreError),
            (correoField, correoError),
            (passwordField, passwordError),
            (confirmField, confirmError)
        ]

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

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
        ])

        // Dynamically chain fields
        var previousAnchor = subtitleLabel.bottomAnchor
        var previousConstant: CGFloat = 36
        for (index, (field, error)) in pairs.enumerated() {
            NSLayoutConstraint.activate([
                field.topAnchor.constraint(equalTo: previousAnchor, constant: previousConstant),
                field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
                field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
                field.heightAnchor.constraint(equalToConstant: fh),
                error.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 4),
                error.leadingAnchor.constraint(equalTo: field.leadingAnchor),
                error.trailingAnchor.constraint(equalTo: field.trailingAnchor),
            ])
            previousAnchor   = error.bottomAnchor
            previousConstant = index == pairs.count - 1 ? 0 : p
        }

        NSLayoutConstraint.activate([
            registerButton.topAnchor.constraint(equalTo: previousAnchor, constant: 36),
            registerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            registerButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            registerButton.heightAnchor.constraint(equalToConstant: AppLayout.buttonHeight),
            loginButton.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: p),
            loginButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loginButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -48)
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

    @objc private func handleRegister() {
        guard validate() else { return }
        do {
            try AuthService.shared.register(
                fullName: nombreField.text ?? "",
                email:    correoField.text ?? "",
                password: passwordField.text ?? ""
            )
            onRegisterSuccess?()
        } catch let error as ServiceError {
            showAlert(title: "Error al registrarse",
                      message: error.errorDescription ?? "")
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    @objc private func handleGoToLogin() { onGoToLogin?() }
    @objc private func fieldsChanged()   { _ = validate() }
    @objc private func tapToDismiss() { view.endEditing(true) }

    @objc private func keyboardWillShow(_ n: NSNotification) {
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            scrollView.contentInset.bottom                  = frame.height + 20
            scrollView.verticalScrollIndicatorInsets.bottom = frame.height
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

        // Nombre
        let nombre = nombreField.text?.trimmed ?? ""
        if nombre.isEmpty {
            setError(nombreError, nombreField, "El nombre es requerido.")
            valid = false
        } else if nombre.count < 3 {
            setError(nombreError, nombreField, "Ingresa tu nombre completo.")
            valid = false
        } else { clearError(nombreError, nombreField) }

        // Correo
        let correo = correoField.text?.trimmed ?? ""
        if correo.isEmpty {
            setError(correoError, correoField, "El correo es requerido.")
            valid = false
        } else if !correo.isValidEmail {
            setError(correoError, correoField, "Formato de correo inválido.")
            valid = false
        } else { clearError(correoError, correoField) }

        // Contraseña
        let pwd = passwordField.text ?? ""
        if pwd.isEmpty {
            setError(passwordError, passwordField, "La contraseña es requerida.")
            valid = false
        } else if pwd.count < 6 {
            setError(passwordError, passwordField, "Mínimo 6 caracteres.")
            valid = false
        } else { clearError(passwordError, passwordField) }

        // Confirmar
        let confirm = confirmField.text ?? ""
        if confirm.isEmpty {
            setError(confirmError, confirmField, "Confirma tu contraseña.")
            valid = false
        } else if confirm != pwd {
            setError(confirmError, confirmField, "Las contraseñas no coinciden.")
            valid = false
        } else { clearError(confirmError, confirmField) }

        registerButton.isEnabled = valid
        registerButton.alpha     = valid ? 1 : 0.6
        return valid
    }

    private func setError(_ label: UILabel, _ field: UITextField, _ msg: String) {
        label.text = msg; label.isHidden = false
        AppStyle.markFieldError(field, hasError: true)
    }
    private func clearError(_ label: UILabel, _ field: UITextField) {
        label.isHidden = true
        AppStyle.markFieldError(field, hasError: false)
    }
}

// MARK: - UITextFieldDelegate

extension RegistroViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nombreField:   correoField.becomeFirstResponder()
        case correoField:   passwordField.becomeFirstResponder()
        case passwordField: confirmField.becomeFirstResponder()
        default:            textField.resignFirstResponder(); handleRegister()
        }
        return true
    }
}
