import Foundation
import CoreData
import CoreLocation

// ─────────────────────────────────────────────
// MARK: - UbicacionService
// ─────────────────────────────────────────────

final class UbicacionService {

    // MARK: Singleton
    static let shared = UbicacionService()
    private init() {}

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.viewContext }

    // ─────────────────────────────────────────
    // MARK: - Save / Update  (upsert)
    // ─────────────────────────────────────────

    /// Persist the map pin for a client via a dedicated Ubicacion entity.
    ///
    /// - Returns: The created or updated `Ubicacion`.
    @discardableResult
    func saveOrUpdate(
        latitude:  Double,
        longitude: Double,
        reference: String?,
        cliente:   Cliente
    ) -> Ubicacion {
        let ubicacion: Ubicacion
        if let existing = cliente.ubicacion {
            ubicacion = existing
        } else {
            let nuevo           = Ubicacion(context: context)
            nuevo.idUbicacion   = UUID()
            nuevo.fechaRegistro = Date()
            nuevo.cliente       = cliente
            ubicacion = nuevo
        }
        ubicacion.latitud             = NSDecimalNumber(value: latitude)
        ubicacion.longitud            = NSDecimalNumber(value: longitude)
        ubicacion.direccionReferencia = reference?.trimmed.isNotBlank == true ? reference?.trimmed : nil
        ubicacion.fechaRegistro       = Date()
        persistence.save()
        return ubicacion
    }

    // ─────────────────────────────────────────
    // MARK: - Device GPS
    // ─────────────────────────────────────────

    /// Returns the device's current CLLocationCoordinate2D via a one-shot
    /// CLLocationManager callback.  Used as the "starting point" for the map
    /// pin — the user then drags to the exact position.
    ///
    /// The completion is called on the main thread.
    /// If location permission is denied, the completion is called with nil.
    func requestCurrentDeviceLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        DeviceLocationHelper.shared.requestOnce(completion: completion)
    }
}

// ─────────────────────────────────────────────
// MARK: - DeviceLocationHelper  (internal, one-shot GPS)
// ─────────────────────────────────────────────

/// Wraps CLLocationManager for a single one-shot coordinate request.
/// Only used by UbicacionService — not exposed publicly.
private final class DeviceLocationHelper: NSObject, CLLocationManagerDelegate {

    static let shared = DeviceLocationHelper()
    private override init() { super.init() }

    private let manager  = CLLocationManager()
    private var callback: ((CLLocationCoordinate2D?) -> Void)?

    func requestOnce(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        callback = completion
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            deliver(nil)
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        deliver(locations.first?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("DeviceLocation error: \(error.localizedDescription)")
        deliver(nil)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            deliver(nil)
        default:
            break
        }
    }

    private func deliver(_ coordinate: CLLocationCoordinate2D?) {
        guard let cb = callback else { return }
        callback = nil
        DispatchQueue.main.async { cb(coordinate) }
    }
}
