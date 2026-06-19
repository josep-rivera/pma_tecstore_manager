import UIKit

final class DetalleProductoViewController: UIViewController {

    // MARK: - Data
    var producto: Producto!

    // MARK: - UI
    private let scrollView     = UIScrollView()
    private let contentView    = UIView()
    private let photoImageView = UIImageView()
    private let nombreLabel    = UILabel()
    private let subtitleLabel  = UILabel()

    // Info card
    private let infoCard         = UIView()
    private let precioTitleLabel = UILabel()
    private let precioLabel      = UILabel()
    private let stockBadge       = UILabel()
    private let cardDiv1         = UIView()
    private let estadoTitleLabel = UILabel()
    private let estadoBadge      = UILabel()
    private let cardDiv2         = UIView()
    private let fechaLabel       = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScrollView()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let updated = ProductoService.shared.fetch(byID: producto.id) { producto = updated }
        populate()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = "Detalle del producto"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Editar", style: .plain, target: self, action: #selector(editProduct))
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.contentMode     = .scaleAspectFill
        photoImageView.clipsToBounds   = true
        photoImageView.backgroundColor = .appSurface

        nombreLabel.translatesAutoresizingMaskIntoConstraints = false
        nombreLabel.font          = AppFont.title2()
        nombreLabel.textColor     = .appTextPrimary
        nombreLabel.numberOfLines = 2

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font      = AppFont.footnote()
        subtitleLabel.textColor = .appTextSecondary

        // Info card container
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoCard.backgroundColor    = .appSurface
        infoCard.layer.cornerRadius = AppLayout.cornerRadius
        infoCard.layer.cornerCurve  = .continuous

        // Row title labels
        for (lbl, text) in [(precioTitleLabel, "Precio"), (estadoTitleLabel, "Estado")] {
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.text      = text
            lbl.font      = AppFont.subheadline()
            lbl.textColor = .appTextSecondary
        }

        precioLabel.translatesAutoresizingMaskIntoConstraints = false
        precioLabel.font      = AppFont.title3()
        precioLabel.textColor = .brandPrimary

        // Pill badges: stock + estado
        for badge in [stockBadge, estadoBadge] {
            badge.translatesAutoresizingMaskIntoConstraints = false
            badge.font               = AppFont.caption1()
            badge.textColor          = .white
            badge.textAlignment      = .center
            badge.layer.cornerRadius = 10
            badge.clipsToBounds      = true
        }

        fechaLabel.translatesAutoresizingMaskIntoConstraints = false
        fechaLabel.font      = AppFont.footnote()
        fechaLabel.textColor = .appTextTertiary

        // Dividers inside card
        for div in [cardDiv1, cardDiv2] {
            div.translatesAutoresizingMaskIntoConstraints = false
            div.backgroundColor = .appSeparator
        }

        infoCard.addSubviews(
            precioTitleLabel, precioLabel, stockBadge,
            cardDiv1,
            estadoTitleLabel, estadoBadge,
            cardDiv2,
            fechaLabel
        )
        contentView.addSubviews(photoImageView, nombreLabel, subtitleLabel, infoCard)
    }

    private func setupConstraints() {
        let p  = AppLayout.padding
        let ph = AppLayout.paddingLarge

        NSLayoutConstraint.activate([
            // Scroll
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Hero photo
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photoImageView.heightAnchor.constraint(equalToConstant: 260),

            // Nombre
            nombreLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: ph),
            nombreLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            nombreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            // Info card
            infoCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: ph),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            infoCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ph),

            // Row 1: Precio (title, left) | price value (trailing of title) | stockBadge (right)
            precioTitleLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: p),
            precioTitleLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            precioTitleLabel.bottomAnchor.constraint(equalTo: cardDiv1.topAnchor, constant: -p),

            precioLabel.centerYAnchor.constraint(equalTo: precioTitleLabel.centerYAnchor),
            precioLabel.leadingAnchor.constraint(equalTo: precioTitleLabel.trailingAnchor, constant: p),

            stockBadge.centerYAnchor.constraint(equalTo: precioTitleLabel.centerYAnchor),
            stockBadge.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -p),
            stockBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
            stockBadge.heightAnchor.constraint(equalToConstant: 26),

            // Divider 1
            cardDiv1.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            cardDiv1.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            cardDiv1.heightAnchor.constraint(equalToConstant: 1),

            // Row 2: Estado
            estadoTitleLabel.topAnchor.constraint(equalTo: cardDiv1.bottomAnchor, constant: p),
            estadoTitleLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            estadoTitleLabel.bottomAnchor.constraint(equalTo: cardDiv2.topAnchor, constant: -p),

            estadoBadge.centerYAnchor.constraint(equalTo: estadoTitleLabel.centerYAnchor),
            estadoBadge.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -p),
            estadoBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            estadoBadge.heightAnchor.constraint(equalToConstant: 26),

            // Divider 2
            cardDiv2.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            cardDiv2.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            cardDiv2.heightAnchor.constraint(equalToConstant: 1),

            // Fecha
            fechaLabel.topAnchor.constraint(equalTo: cardDiv2.bottomAnchor, constant: p),
            fechaLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            fechaLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -p),
            fechaLabel.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -p),
        ])
    }

    // MARK: - Populate

    private func populate() {
        guard let p = producto else { return }

        let placeholder = UIImage(systemName: "shippingbox.fill")?.withRenderingMode(.alwaysTemplate)
        photoImageView.setImage(from: p.productImagePath, placeholder: placeholder)
        photoImageView.tintColor = p.productImagePath == nil ? .appTextTertiary : nil

        nombreLabel.text   = p.productName
        subtitleLabel.text = "\(p.productCode)  ·  \(p.categoryValue)"
        precioLabel.text   = p.priceDouble.asCurrency

        let stockInt = p.stockInt
        stockBadge.text            = "  \(stockInt) \(stockInt == 1 ? "unidad" : "unidades")  "
        stockBadge.backgroundColor = stockInt.stockUIColor

        let active = p.isActive
        estadoBadge.text            = "  \(p.statusValue)  "
        estadoBadge.backgroundColor = active ? .appSuccess : .appTextSecondary

        fechaLabel.text = "Registrado el \(p.registrationDate.displayDate)"
    }

    // MARK: - Actions

    @objc private func editProduct() {
        let formVC      = FormularioProductoViewController()
        formVC.producto = producto
        formVC.onSave   = { }
        navigationController?.pushViewController(formVC, animated: true)
    }
}
