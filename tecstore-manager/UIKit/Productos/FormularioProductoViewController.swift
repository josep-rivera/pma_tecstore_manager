import UIKit
import PhotosUI

final class FormularioProductoViewController: UIViewController {

    // MARK: - Mode
    var producto: Producto?                 // nil → create,  non-nil → edit
    var onSave: (() -> Void)?

    private var isEditMode: Bool { producto != nil }
    private var selectedPhotoPath: String?
    private var selectedCategory: String = ProductCategory.otros.rawValue
    private var generatedCode: String = ""

    // ── Category picker state
    private let categories = ProductCategory.allCases.map(\.rawValue)
    private var categoryPickerView = UIPickerView()

    // MARK: - UI Elements
    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    private let photoButton     = UIButton(type: .custom)
    private let photoImageView  = UIImageView()

    private let nombreField     = UITextField()
    private let nombreError     = AppStyle.makeErrorLabel()
    private let categoriaField  = UITextField()   // input view = UIPickerView
    private let categoriaError  = AppStyle.makeErrorLabel()
    private let precioField     = UITextField()
    private let precioError     = AppStyle.makeErrorLabel()
    private let stockField      = UITextField()
    private let stockError      = AppStyle.makeErrorLabel()

    private let estadoLabel     = AppStyle.makeFieldLabel("Estado")
    private let estadoSwitch    = UISwitch()
    private let estadoValueLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScrollView()
        setupPhoto()
        setupFields()
        setupEstado()
        setupConstraints()
        setupKeyboard()
        if isEditMode {
            populateFields()
        } else {
            refreshAutoCode()
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = isEditMode ? "Editar producto" : "Nuevo producto"
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

    private func setupPhoto() {
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.contentMode        = .scaleAspectFill
        photoImageView.clipsToBounds      = true
        photoImageView.layer.cornerRadius = AppLayout.cornerRadius
        photoImageView.layer.cornerCurve  = .continuous
        photoImageView.layer.borderWidth  = 1.5
        photoImageView.layer.borderColor  = UIColor.brandLight.cgColor
        photoImageView.backgroundColor    = .appSurface

        let cameraIcon = UIImage(systemName: "camera.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 40, weight: .light))
            .withRenderingMode(.alwaysTemplate)
        photoImageView.image     = cameraIcon
        photoImageView.tintColor = .appTextTertiary

        photoButton.translatesAutoresizingMaskIntoConstraints = false
        photoButton.addTarget(self, action: #selector(handleSelectPhoto), for: .touchUpInside)

        contentView.addSubviews(photoImageView, photoButton,
                                nombreField, nombreError,
                                categoriaField, categoriaError,
                                precioField, precioError,
                                stockField, stockError,
                                estadoLabel, estadoSwitch, estadoValueLabel)
    }

    private func setupFields() {
        let configs: [(UITextField, String, String, UIKeyboardType, UIReturnKeyType)] = [
            (nombreField,    "Nombre del producto",   "tag",           .default,       .next),
            (precioField,    "0.00",                  "dollarsign.circle", .decimalPad, .done),
            (stockField,     "0",                     "number",        .numberPad,    .done)
        ]
        for (field, ph, icon, keyboard, ret) in configs {
            AppStyle.style(textField: field, placeholder: ph, icon: icon,
                           keyboardType: keyboard, returnKey: ret)
            field.translatesAutoresizingMaskIntoConstraints = false
            field.delegate = self
            field.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        }
        nombreField.autocapitalizationType = .words

        // Categoria field with UIPickerView as inputView
        AppStyle.style(textField: categoriaField, placeholder: "Selecciona una categoría", icon: "tag.fill")
        categoriaField.text = selectedCategory
        categoriaField.translatesAutoresizingMaskIntoConstraints = false
        categoriaField.tintColor = .clear   // hide cursor

        categoryPickerView.delegate   = self
        categoryPickerView.dataSource = self
        categoriaField.inputView      = categoryPickerView
        if let index = categories.firstIndex(of: selectedCategory) {
            categoryPickerView.selectRow(index, inComponent: 0, animated: false)
        }

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn   = UIBarButtonItem(title: "Listo", style: .prominent,
                                         target: self, action: #selector(categoryPickerDone))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        categoriaField.inputAccessoryView = toolbar
        categoriaField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
    }

    private func setupEstado() {
        estadoLabel.translatesAutoresizingMaskIntoConstraints = false
        estadoSwitch.translatesAutoresizingMaskIntoConstraints = false
        estadoSwitch.isOn = true
        estadoSwitch.onTintColor = .appSuccess
        estadoSwitch.addTarget(self, action: #selector(estadoChanged), for: .valueChanged)

        estadoValueLabel.translatesAutoresizingMaskIntoConstraints = false
        estadoValueLabel.font      = AppFont.subheadline()
        estadoValueLabel.textColor = .appSuccess
        estadoValueLabel.text      = "Activo"
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

            // Photo — full-width rectangular preview
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: p),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            photoImageView.heightAnchor.constraint(equalToConstant: 160),
            photoButton.topAnchor.constraint(equalTo: photoImageView.topAnchor),
            photoButton.leadingAnchor.constraint(equalTo: photoImageView.leadingAnchor),
            photoButton.trailingAnchor.constraint(equalTo: photoImageView.trailingAnchor),
            photoButton.bottomAnchor.constraint(equalTo: photoImageView.bottomAnchor),
        ])

        // Chain form fields
        let fieldRows: [(UITextField, UILabel)] = [
            (nombreField,    nombreError),
            (categoriaField, categoriaError),
            (precioField,    precioError),
            (stockField,     stockError)
        ]
        var prevBottom = photoImageView.bottomAnchor
        var prevConst: CGFloat = p

        for (field, error) in fieldRows {
            NSLayoutConstraint.activate([
                field.topAnchor.constraint(equalTo: prevBottom, constant: prevConst),
                field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
                field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
                field.heightAnchor.constraint(equalToConstant: fh),
                error.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 4),
                error.leadingAnchor.constraint(equalTo: field.leadingAnchor),
                error.trailingAnchor.constraint(equalTo: field.trailingAnchor)
            ])
            prevBottom = error.bottomAnchor
            prevConst  = p
        }

        // Estado row
        NSLayoutConstraint.activate([
            estadoLabel.topAnchor.constraint(equalTo: prevBottom, constant: p + 4),
            estadoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            estadoSwitch.centerYAnchor.constraint(equalTo: estadoLabel.centerYAnchor),
            estadoSwitch.leadingAnchor.constraint(equalTo: estadoLabel.trailingAnchor, constant: p),
            estadoValueLabel.centerYAnchor.constraint(equalTo: estadoSwitch.centerYAnchor),
            estadoValueLabel.leadingAnchor.constraint(equalTo: estadoSwitch.trailingAnchor, constant: p),
            estadoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -p - 32)
        ])
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Populate (edit mode)

    private func populateFields() {
        guard let p = producto else { return }
        generatedCode       = p.productCode
        nombreField.text    = p.productName
        categoriaField.text = p.categoryValue
        selectedCategory    = p.categoryValue
        precioField.text    = String(format: "%.2f", p.priceDouble)
        stockField.text     = "\(p.stockInt)"
        estadoSwitch.isOn   = p.isActive
        updateEstadoLabel()

        if let path = p.productImagePath {
            photoImageView.setImage(from: path)
            photoImageView.tintColor = nil
        }

        // Sync picker selection
        if let index = categories.firstIndex(of: p.categoryValue) {
            categoryPickerView.selectRow(index, inComponent: 0, animated: false)
        }
    }

    // MARK: - Actions

    @objc private func handleSave() {
        guard validate() else { return }

        let code      = generatedCode
        let name      = nombreField.text?.trimmed ?? ""
        let category  = selectedCategory
        let priceStr  = precioField.text?.trimmed ?? "0"
        let stockStr  = stockField.text?.trimmed ?? "0"
        let price     = Decimal(string: priceStr) ?? 0
        let stock     = Int(stockStr) ?? 0
        let estado    = estadoSwitch.isOn ? "Activo" : "Inactivo"

        do {
            if isEditMode, let p = producto {
                try ProductoService.shared.update(p, code: code, name: name, category: category,
                                                  price: price, stock: stock,
                                                  photoPath: selectedPhotoPath ?? p.productImagePath,
                                                  estado: estado)
            } else {
                try ProductoService.shared.create(code: code, name: name, category: category,
                                                  price: price, stock: stock,
                                                  photoPath: selectedPhotoPath)
            }
            onSave?()
            navigationController?.popViewController(animated: true)
        } catch let error as ServiceError {
            showAlert(title: "Error al guardar", message: error.errorDescription ?? "")
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    @objc private func handleSelectPhoto() {
        showImageSourcePicker { [weak self] in self?.openCamera() }
                              onGallery: { [weak self] in self?.openGallery() }
    }

    private func openCamera() {
        let picker = UIImagePickerController()
        picker.sourceType  = .camera
        picker.delegate    = self
        present(picker, animated: true)
    }

    private func openGallery() {
        var config = PHPickerConfiguration()
        config.filter          = .images
        config.selectionLimit  = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    /// Resize, persist, and preview a picked image. Shared by camera and gallery.
    private func applyPickedImage(_ image: UIImage) {
        let resized   = image.resized(maxDimension: 800)
        let fileName  = "\(UUID().compact).jpg"
        selectedPhotoPath        = resized.saveToDocuments(named: fileName)
        photoImageView.image     = resized
        photoImageView.tintColor = nil
    }

    @objc private func categoryPickerDone() {
        categoriaField.resignFirstResponder()
        let row = categoryPickerView.selectedRow(inComponent: 0)
        selectedCategory    = categories[row]
        categoriaField.text = selectedCategory
        if !isEditMode { refreshAutoCode() }
        _ = validate()
    }

    private func refreshAutoCode() {
        generatedCode = ProductoService.shared.generateCode(for: selectedCategory)
    }

    @objc private func estadoChanged() { updateEstadoLabel() }

    private func updateEstadoLabel() {
        estadoValueLabel.text      = estadoSwitch.isOn ? "Activo" : "Inactivo"
        estadoValueLabel.textColor = estadoSwitch.isOn ? .appSuccess : .appTextSecondary
    }

    @objc private func fieldsChanged() { _ = validate() }
    @objc private func tapToDismiss() { view.endEditing(true) }
    @objc private func keyboardWillShow(_ n: NSNotification) {
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            scrollView.contentInset.bottom = frame.height + 20
        }
    }
    @objc private func keyboardWillHide(_ n: NSNotification) {
        scrollView.contentInset.bottom = 0
    }

    // MARK: - Validation

    @discardableResult
    private func validate() -> Bool {
        var valid = true

        let nombre = nombreField.text?.trimmed ?? ""
        if nombre.isEmpty {
            setError(nombreError, nombreField, "El nombre es requerido.")
            valid = false
        } else { clearError(nombreError, nombreField) }

        if selectedCategory.isEmpty {
            setError(categoriaError, categoriaField, "Selecciona una categoría.")
            valid = false
        } else { clearError(categoriaError, categoriaField) }

        let precioStr = precioField.text?.trimmed ?? ""
        if precioStr.isEmpty {
            setError(precioError, precioField, "El precio es requerido.")
            valid = false
        } else if Decimal(string: precioStr) == nil {
            setError(precioError, precioField, "Ingresa un precio válido.")
            valid = false
        } else if let precio = Decimal(string: precioStr), precio <= 0 {
            setError(precioError, precioField, "El precio debe ser mayor a 0.")
            valid = false
        } else { clearError(precioError, precioField) }

        let stockStr = stockField.text?.trimmed ?? ""
        if stockStr.isEmpty {
            setError(stockError, stockField, "El stock es requerido.")
            valid = false
        } else if let s = Int(stockStr), s < 0 {
            setError(stockError, stockField, "El stock no puede ser negativo.")
            valid = false
        } else if Int(stockStr) == nil {
            setError(stockError, stockField, "Ingresa un stock válido.")
            valid = false
        } else { clearError(stockError, stockField) }

        navigationItem.rightBarButtonItem?.isEnabled = valid
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

extension FormularioProductoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nombreField:    categoriaField.becomeFirstResponder()
        case categoriaField: precioField.becomeFirstResponder()
        case precioField:    stockField.becomeFirstResponder()
        default:             textField.resignFirstResponder()
        }
        return true
    }

}

// MARK: - UIPickerViewDataSource / Delegate

extension FormularioProductoViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        categories.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        categories[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCategory    = categories[row]
        categoriaField.text = selectedCategory
    }
}

// MARK: - UIImagePickerControllerDelegate (camera only)

extension FormularioProductoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else { return }
        applyPickedImage(image)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate (gallery)

extension FormularioProductoViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async { self?.applyPickedImage(image) }
        }
    }
}
