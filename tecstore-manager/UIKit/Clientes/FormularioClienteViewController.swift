import UIKit
import MapKit
import CoreLocation

final class FormularioClienteViewController: UIViewController {

    // MARK: - Mode
    var cliente: Cliente?
    var onSave:  (() -> Void)?

    private var isEditMode: Bool { cliente != nil }
    private var selectedLatitude:  Double = 0
    private var selectedLongitude: Double = 0
    private var selectedAnnotation = MKPointAnnotation()

    private var activeSearch: MKLocalSearch?
    private var geocodeTimer: Timer?

    // MARK: - UI
    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    private let dniField       = UITextField()
    private let dniError       = AppStyle.makeErrorLabel()
    private let nombresField   = UITextField()
    private let nombresError   = AppStyle.makeErrorLabel()
    private let apellidosField = UITextField()
    private let apellidosError = AppStyle.makeErrorLabel()
    private let telefonoField  = UITextField()
    private let correoField    = UITextField()
    private let correoError    = AppStyle.makeErrorLabel()
    private let direccionField = UITextField()

    private let estadoLabel      = AppStyle.makeFieldLabel("Estado")
    private let estadoSwitch     = UISwitch()
    private let estadoValueLabel = UILabel()

    private let locationHeaderLabel  = UILabel()
    private let mapView              = MKMapView()
    private let mapHintLabel         = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScrollView()
        setupFields()
        setupEstado()
        setupLocationSection()
        setupConstraints()
        setupKeyboard()
        if isEditMode { populateFields() } else { navigationItem.rightBarButtonItem?.isEnabled = false }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = isEditMode ? "Editar cliente" : "Nuevo cliente"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Guardar", style: .prominent, target: self, action: #selector(handleSave))
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }

    private func setupFields() {
        let configs: [(UITextField, String, String, UIKeyboardType, UIReturnKeyType, Bool)] = [
            (dniField,       "DNI (8 dígitos)",       "creditcard",  .numberPad,    .next, false),
            (nombresField,   "Nombres",                "person",      .default,      .next, false),
            (apellidosField, "Apellidos",              "person.fill", .default,      .next, false),
            (telefonoField,  "Teléfono (opcional)",    "phone",       .phonePad,     .next, false),
            (correoField,    "Correo (opcional)",      "envelope",    .emailAddress, .next, false),
            (direccionField, "Dirección (opcional)",   "mappin",      .default,      .done, false)
        ]
        for (field, ph, icon, kb, ret, sec) in configs {
            AppStyle.style(textField: field, placeholder: ph, icon: icon,
                           isSecure: sec, keyboardType: kb, returnKey: ret)
            field.translatesAutoresizingMaskIntoConstraints = false
            field.delegate = self
            field.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        }
        nombresField.autocapitalizationType   = .words
        apellidosField.autocapitalizationType = .words
        direccionField.autocapitalizationType = .words
        dniField.addTarget(self, action: #selector(dniChanged), for: .editingChanged)
        direccionField.addTarget(self, action: #selector(direccionChanged), for: .editingChanged)

        contentView.addSubviews(dniField, dniError,
                                nombresField, nombresError,
                                apellidosField, apellidosError,
                                telefonoField,
                                correoField, correoError,
                                direccionField,
                                estadoLabel, estadoSwitch, estadoValueLabel)
    }

    private func setupEstado() {
        estadoLabel.translatesAutoresizingMaskIntoConstraints  = false
        estadoSwitch.translatesAutoresizingMaskIntoConstraints = false
        estadoSwitch.isOn       = true
        estadoSwitch.onTintColor = .appSuccess
        estadoSwitch.addTarget(self, action: #selector(estadoChanged), for: .valueChanged)

        estadoValueLabel.translatesAutoresizingMaskIntoConstraints = false
        estadoValueLabel.font      = AppFont.subheadline()
        estadoValueLabel.textColor = .appSuccess
        estadoValueLabel.text      = "Activo"
    }

    private func setupLocationSection() {
        locationHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        locationHeaderLabel.text      = "Ubicación del cliente"
        locationHeaderLabel.font      = AppFont.headline()
        locationHeaderLabel.textColor = .appTextPrimary

        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = AppLayout.cornerRadius
        mapView.clipsToBounds      = true
        mapView.delegate           = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        mapView.addGestureRecognizer(tap)

        mapHintLabel.translatesAutoresizingMaskIntoConstraints = false
        mapHintLabel.text          = "Toca el mapa para colocar el pin"
        mapHintLabel.font          = AppFont.caption1()
        mapHintLabel.textColor     = .appTextSecondary
        mapHintLabel.textAlignment = .center

        contentView.addSubviews(locationHeaderLabel, mapView, mapHintLabel)
    }

    private func setupConstraints() {
        let ph = AppLayout.paddingLarge
        let p  = AppLayout.padding
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
        ])

        let rows: [(UITextField, UILabel?)] = [
            (dniField,       dniError),
            (nombresField,   nombresError),
            (apellidosField, apellidosError),
            (telefonoField,  nil),
            (correoField,    correoError),
            (direccionField, nil)
        ]
        var prevBottom = contentView.topAnchor
        var prevConst: CGFloat = p

        for (field, error) in rows {
            NSLayoutConstraint.activate([
                field.topAnchor.constraint(equalTo: prevBottom, constant: prevConst),
                field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
                field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
                field.heightAnchor.constraint(equalToConstant: fh),
            ])
            if let error {
                NSLayoutConstraint.activate([
                    error.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 4),
                    error.leadingAnchor.constraint(equalTo: field.leadingAnchor),
                    error.trailingAnchor.constraint(equalTo: field.trailingAnchor),
                ])
                prevBottom = error.bottomAnchor
            } else {
                prevBottom = field.bottomAnchor
            }
            prevConst = p
        }

        NSLayoutConstraint.activate([
            estadoLabel.topAnchor.constraint(equalTo: prevBottom, constant: p + 4),
            estadoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            estadoSwitch.centerYAnchor.constraint(equalTo: estadoLabel.centerYAnchor),
            estadoSwitch.leadingAnchor.constraint(equalTo: estadoLabel.trailingAnchor, constant: p),
            estadoValueLabel.centerYAnchor.constraint(equalTo: estadoSwitch.centerYAnchor),
            estadoValueLabel.leadingAnchor.constraint(equalTo: estadoSwitch.trailingAnchor, constant: p),

            locationHeaderLabel.topAnchor.constraint(equalTo: estadoLabel.bottomAnchor, constant: ph),
            locationHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),

            mapView.topAnchor.constraint(equalTo: locationHeaderLabel.bottomAnchor, constant: p),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            mapView.heightAnchor.constraint(equalToConstant: 200),

            mapHintLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 6),
            mapHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            mapHintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            mapHintLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -p)
        ])
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        geocodeTimer?.invalidate()
        activeSearch?.cancel()
    }

    // MARK: - Populate

    private func populateFields() {
        guard let c = cliente else { return }
        dniField.text       = c.dniValue
        nombresField.text   = c.firstNames
        apellidosField.text = c.lastNames
        telefonoField.text  = c.phoneNumber
        correoField.text    = c.emailValue
        direccionField.text = c.addressValue
        estadoSwitch.isOn   = c.isActive
        updateEstadoLabel()

        if c.hasValidCoordinates {
            setMapPin(lat: c.latitude, lon: c.longitude)
        } else {
            centerMapOnLima()
        }
    }

    // MARK: - Map Helpers

    private func setMapPin(lat: Double, lon: Double) {
        selectedLatitude  = lat
        selectedLongitude = lon
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        selectedAnnotation.coordinate = coord
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(selectedAnnotation)
        let region = MKCoordinateRegion(center: coord,
                                        latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }

    private func centerMapOnLima() {
        let lima   = CLLocationCoordinate2D(latitude: -12.0464, longitude: -77.0428)
        let region = MKCoordinateRegion(center: lima,
                                        latitudinalMeters: 10_000, longitudinalMeters: 10_000)
        mapView.setRegion(region, animated: false)
    }

    // MARK: - Actions

    @objc private func handleSave() {
        guard validate() else { return }
        do {
            let dni       = dniField.text?.trimmed ?? ""
            let nombres   = nombresField.text?.trimmed ?? ""
            let apellidos = apellidosField.text?.trimmed ?? ""
            let telefono  = telefonoField.text
            let correo    = correoField.text
            let direccion = direccionField.text

            let savedCliente: Cliente
            if isEditMode, let c = cliente {
                try ClienteService.shared.update(c, dni: dni, nombres: nombres,
                                                 apellidos: apellidos, telefono: telefono,
                                                 correo: correo, direccion: direccion,
                                                 estado: estadoSwitch.isOn ? "Activo" : "Inactivo")
                savedCliente = c
            } else {
                savedCliente = try ClienteService.shared.create(
                    dni: dni, nombres: nombres, apellidos: apellidos,
                    telefono: telefono, correo: correo, direccion: direccion)
            }

            if selectedLatitude != 0 || selectedLongitude != 0 {
                UbicacionService.shared.saveOrUpdate(
                    latitude: selectedLatitude, longitude: selectedLongitude,
                    reference: direccionField.text, cliente: savedCliente)
            }
            onSave?()
            navigationController?.popViewController(animated: true)
        } catch let error as ServiceError {
            showAlert(title: "Error al guardar", message: error.errorDescription ?? "")
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    @objc private func mapTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coord = mapView.convert(point, toCoordinateFrom: mapView)
        setMapPin(lat: coord.latitude, lon: coord.longitude)
        mapHintLabel.text      = "Pin colocado · toca para mover"
        mapHintLabel.textColor = .brandPrimary

        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        Task { [weak self] in
            guard let self else { return }
            guard let request = MKReverseGeocodingRequest(location: location),
                  let item = try? await request.mapItems.first else { return }
            let address = item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true) ?? ""
            if !address.isEmpty {
                await MainActor.run { self.direccionField.text = address }
            }
        }
    }

    @objc private func direccionChanged() {
        geocodeTimer?.invalidate()
        let text = direccionField.text?.trimmed ?? ""
        guard text.count > 6 else { return }
        geocodeTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: false) { [weak self] _ in
            self?.geocodeAddress(text)
        }
    }

    private func geocodeAddress(_ address: String) {
        activeSearch?.cancel()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        activeSearch = MKLocalSearch(request: request)
        activeSearch?.start { [weak self] response, _ in
            guard let item = response?.mapItems.first else { return }
            let coord = item.location.coordinate
            DispatchQueue.main.async {
                self?.setMapPin(lat: coord.latitude, lon: coord.longitude)
                self?.mapHintLabel.text      = "Ubicación encontrada"
                self?.mapHintLabel.textColor = .brandPrimary
            }
        }
    }

    @objc private func estadoChanged() { updateEstadoLabel() }
    private func updateEstadoLabel() {
        estadoValueLabel.text      = estadoSwitch.isOn ? "Activo" : "Inactivo"
        estadoValueLabel.textColor = estadoSwitch.isOn ? .appSuccess : .appTextSecondary
    }

    @objc private func fieldsChanged() { _ = validate() }
    @objc private func dniChanged() {
        if let text = dniField.text, text.count > 8 {
            dniField.text = String(text.prefix(8))
        }
        _ = validate()
    }
    @objc private func tapToDismiss() { view.endEditing(true) }
    @objc private func keyboardWillShow(_ n: NSNotification) {
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            scrollView.contentInset.bottom = frame.height + 20
        }
    }
    @objc private func keyboardWillHide(_ n: NSNotification) { scrollView.contentInset.bottom = 0 }

    // MARK: - Validation

    @discardableResult
    private func validate() -> Bool {
        var valid = true

        let dni = dniField.text?.trimmed ?? ""
        if dni.isEmpty {
            setError(dniError, dniField, "El DNI es requerido.")
            valid = false
        } else if !dni.isValidDNI {
            setError(dniError, dniField, "El DNI debe tener exactamente 8 dígitos.")
            valid = false
        } else { clearError(dniError, dniField) }

        let nombres = nombresField.text?.trimmed ?? ""
        if nombres.isEmpty {
            setError(nombresError, nombresField, "Los nombres son requeridos.")
            valid = false
        } else { clearError(nombresError, nombresField) }

        let apellidos = apellidosField.text?.trimmed ?? ""
        if apellidos.isEmpty {
            setError(apellidosError, apellidosField, "Los apellidos son requeridos.")
            valid = false
        } else { clearError(apellidosError, apellidosField) }

        let correo = correoField.text?.trimmed ?? ""
        if correo.isNotBlank && !correo.isValidEmail {
            setError(correoError, correoField, "Formato de correo inválido.")
            valid = false
        } else { clearError(correoError, correoField) }

        navigationItem.rightBarButtonItem?.isEnabled = valid
        return valid
    }

    private func setError(_ l: UILabel, _ f: UITextField, _ m: String) {
        l.text = m; l.isHidden = false; AppStyle.markFieldError(f, hasError: true)
    }
    private func clearError(_ l: UILabel, _ f: UITextField) {
        l.isHidden = true; AppStyle.markFieldError(f, hasError: false)
    }
}

extension FormularioClienteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case dniField:       nombresField.becomeFirstResponder()
        case nombresField:   apellidosField.becomeFirstResponder()
        case apellidosField: telefonoField.becomeFirstResponder()
        case telefonoField:  correoField.becomeFirstResponder()
        case correoField:    direccionField.becomeFirstResponder()
        default:             textField.resignFirstResponder()
        }
        return true
    }
}

extension FormularioClienteViewController: MKMapViewDelegate {}
