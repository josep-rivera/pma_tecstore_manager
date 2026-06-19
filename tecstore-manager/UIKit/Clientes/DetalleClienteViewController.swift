import UIKit
import MapKit

final class DetalleClienteViewController: UIViewController {

    // MARK: - Data
    var cliente: Cliente!

    // MARK: - UI
    private let scrollView   = UIScrollView()
    private let contentView  = UIView()

    // Header
    private let avatarView   = UIView()
    private let avatarLetter = UILabel()
    private let nameLabel    = UILabel()
    private let statusBadge  = UILabel()

    // Contact card
    private let contactCard    = UIView()
    private let dniLabel       = UILabel()
    private let contactDiv1    = UIView()
    private let telefonoLabel  = UILabel()
    private let contactDiv2    = UIView()
    private let correoLabel    = UILabel()
    private let contactDiv3    = UIView()
    private let direccionLabel = UILabel()
    private let contactDiv4    = UIView()
    private let fechaLabel     = UILabel()

    // Map
    private let mapView        = MKMapView()
    private let noLocationLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScrollView()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let updated = ClienteService.shared.fetch(byID: cliente.id) { cliente = updated }
        populate()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = "Detalle del cliente"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Editar", style: .plain, target: self, action: #selector(editCliente))
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Avatar (96pt)
        let avatarSize: CGFloat = 96
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.backgroundColor    = .brandLight
        avatarView.constrainSize(width: avatarSize, height: avatarSize)

        avatarLetter.translatesAutoresizingMaskIntoConstraints = false
        avatarLetter.font          = AppFont.title1()
        avatarLetter.textColor     = .brandPrimary
        avatarLetter.textAlignment = .center
        avatarView.addSubview(avatarLetter)
        avatarLetter.pinEdges(to: avatarView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font          = AppFont.title2()
        nameLabel.textColor     = .appTextPrimary
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0

        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.font               = AppFont.subheadline()
        statusBadge.textColor          = .white
        statusBadge.textAlignment      = .center
        statusBadge.layer.cornerRadius = 10
        statusBadge.clipsToBounds      = true

        // Contact card
        contactCard.translatesAutoresizingMaskIntoConstraints = false
        contactCard.backgroundColor    = .appSurface
        contactCard.layer.cornerRadius = AppLayout.cornerRadius
        contactCard.layer.cornerCurve  = .continuous

        for lbl in [dniLabel, telefonoLabel, correoLabel, direccionLabel] {
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.font          = AppFont.body()
            lbl.textColor     = .appTextSecondary
            lbl.numberOfLines = 0
        }

        fechaLabel.translatesAutoresizingMaskIntoConstraints = false
        fechaLabel.font      = AppFont.footnote()
        fechaLabel.textColor = .appTextTertiary

        for div in [contactDiv1, contactDiv2, contactDiv3, contactDiv4] {
            div.translatesAutoresizingMaskIntoConstraints = false
            div.backgroundColor = .appSeparator
        }

        contactCard.addSubviews(
            dniLabel, contactDiv1,
            telefonoLabel, contactDiv2,
            correoLabel, contactDiv3,
            direccionLabel, contactDiv4,
            fechaLabel
        )

        // Map
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius       = AppLayout.cornerRadius
        mapView.layer.cornerCurve        = .continuous
        mapView.clipsToBounds            = true
        mapView.isUserInteractionEnabled = false

        noLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        noLocationLabel.text          = "Sin ubicación registrada"
        noLocationLabel.font          = AppFont.footnote()
        noLocationLabel.textColor     = .appTextTertiary
        noLocationLabel.textAlignment = .center

        contentView.addSubviews(
            avatarView, nameLabel, statusBadge,
            contactCard,
            mapView, noLocationLabel
        )
    }

    private func setupConstraints() {
        let ph = AppLayout.paddingLarge
        let p  = AppLayout.padding

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

            // Header
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ph),
            avatarView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: p),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            statusBadge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            statusBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            statusBadge.heightAnchor.constraint(equalToConstant: 30),
            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),

            // Contact card
            contactCard.topAnchor.constraint(equalTo: statusBadge.bottomAnchor, constant: ph),
            contactCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            contactCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            // DNI row
            dniLabel.topAnchor.constraint(equalTo: contactCard.topAnchor, constant: p),
            dniLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            dniLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),

            contactDiv1.topAnchor.constraint(equalTo: dniLabel.bottomAnchor, constant: p),
            contactDiv1.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor),
            contactDiv1.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor),
            contactDiv1.heightAnchor.constraint(equalToConstant: 1),

            // Teléfono row
            telefonoLabel.topAnchor.constraint(equalTo: contactDiv1.bottomAnchor, constant: p),
            telefonoLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            telefonoLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),

            contactDiv2.topAnchor.constraint(equalTo: telefonoLabel.bottomAnchor, constant: p),
            contactDiv2.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor),
            contactDiv2.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor),
            contactDiv2.heightAnchor.constraint(equalToConstant: 1),

            // Correo row
            correoLabel.topAnchor.constraint(equalTo: contactDiv2.bottomAnchor, constant: p),
            correoLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            correoLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),

            contactDiv3.topAnchor.constraint(equalTo: correoLabel.bottomAnchor, constant: p),
            contactDiv3.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor),
            contactDiv3.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor),
            contactDiv3.heightAnchor.constraint(equalToConstant: 1),

            // Dirección row
            direccionLabel.topAnchor.constraint(equalTo: contactDiv3.bottomAnchor, constant: p),
            direccionLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            direccionLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),

            contactDiv4.topAnchor.constraint(equalTo: direccionLabel.bottomAnchor, constant: p),
            contactDiv4.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor),
            contactDiv4.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor),
            contactDiv4.heightAnchor.constraint(equalToConstant: 1),

            // Fecha
            fechaLabel.topAnchor.constraint(equalTo: contactDiv4.bottomAnchor, constant: p),
            fechaLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            fechaLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),
            fechaLabel.bottomAnchor.constraint(equalTo: contactCard.bottomAnchor, constant: -p),

            // Map
            mapView.topAnchor.constraint(equalTo: contactCard.bottomAnchor, constant: ph),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            mapView.heightAnchor.constraint(equalToConstant: 200),
            mapView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ph),

            noLocationLabel.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            noLocationLabel.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
        ])
    }

    // MARK: - Populate

    private func iconText(_ label: UILabel, icon: String, text: String) {
        guard let img = UIImage(systemName: icon)?
            .withTintColor(.appTextSecondary, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)) else {
            label.text = text; return
        }
        let attach    = NSTextAttachment()
        attach.image  = img
        attach.bounds = CGRect(x: 0, y: -3, width: 17, height: 17)
        let full      = NSMutableAttributedString(attachment: attach)
        full.append(NSAttributedString(
            string:     "  \(text)",
            attributes: [.font: AppFont.body(), .foregroundColor: UIColor.appTextSecondary]
        ))
        label.attributedText = full
    }

    private func populate() {
        guard let c = cliente else { return }

        let initial       = c.firstNames.first.map { String($0) } ?? "?"
        avatarLetter.text = initial.uppercased()
        nameLabel.text    = c.fullName

        statusBadge.text            = "  \(c.statusValue)  "
        statusBadge.backgroundColor = c.isActive ? .appSuccess : .appTextSecondary

        iconText(dniLabel,       icon: "creditcard",    text: "DNI: \(c.dniValue)")
        iconText(telefonoLabel,  icon: "phone",         text: c.phoneNumber  ?? "Sin teléfono")
        iconText(correoLabel,    icon: "envelope",      text: c.emailValue   ?? "Sin correo")
        iconText(direccionLabel, icon: "mappin.circle", text: c.addressValue ?? "Sin dirección")
        fechaLabel.text = "Registrado el \(c.registrationDate.displayDate)"

        if c.hasValidCoordinates {
            noLocationLabel.isHidden = true
            let coord    = CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
            let pin      = MKPointAnnotation()
            pin.title    = c.fullName
            pin.subtitle = c.locationReference
            pin.coordinate = coord
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(pin)
            let region = MKCoordinateRegion(center: coord,
                                            latitudinalMeters: 1500, longitudinalMeters: 1500)
            mapView.setRegion(region, animated: false)
        } else {
            noLocationLabel.isHidden = false
            mapView.removeAnnotations(mapView.annotations)
        }
    }

    // MARK: - Actions

    @objc private func editCliente() {
        let formVC     = FormularioClienteViewController()
        formVC.cliente = cliente
        formVC.onSave  = { }
        navigationController?.pushViewController(formVC, animated: true)
    }
}
