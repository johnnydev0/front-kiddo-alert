//
//  LocationManager.swift
//  alert
//
//  Phase 2: Real location services and geofencing
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var lastUpdateTime: Date?
    @Published var isLocationSharingActive = true // For child mode
    @Published var locationError: String?

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var geofenceRegions: [String: CLCircularRegion] = [:]

    // Track which regions we're currently inside (for manual detection)
    private var currentlyInsideRegions: Set<String> = []

    // Callback for geofence events
    var onGeofenceEvent: ((GeofenceEvent) -> Void)?

    // MARK: - Configuration
    private let updateInterval: TimeInterval = 5 * 60 // 5 minutes (configurable for future .env)
    private let geofenceRadius: CLLocationDistance = 150 // 150 meters (increased for better detection)

    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update every 50 meters

        // Only enable background updates if we have the capability configured
        // This prevents crash in simulator/debug builds
        // To enable: Target > Signing & Capabilities > Background Modes > Location updates
        #if !targetEnvironment(simulator)
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        }
        #endif

        // Get initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permission Management
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            locationError = "Permissão de localização negada. Ative nas Configurações."
        @unknown default:
            break
        }
    }

    // MARK: - Location Updates
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            locationError = "Permissão de localização necessária"
            return
        }

        guard isLocationSharingActive else {
            return
        }

        locationManager.startUpdatingLocation()
        lastUpdateTime = Date()
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }

    func pauseLocationSharing() {
        isLocationSharingActive = false
        stopLocationUpdates()

        // Trigger pause event
        onGeofenceEvent?(.sharingPaused(childName: "Criança"))
    }

    func resumeLocationSharing() {
        isLocationSharingActive = true
        startLocationUpdates()

        // Trigger resume event
        onGeofenceEvent?(.sharingResumed(childName: "Criança"))
    }

    // MARK: - Geofencing
    func addGeofence(id: String, name: String, latitude: Double, longitude: Double, radius: CLLocationDistance? = nil) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            locationError = "Geofencing não disponível neste dispositivo"
            return
        }

        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(
            center: center,
            radius: radius ?? geofenceRadius,
            identifier: id
        )

        region.notifyOnEntry = true
        region.notifyOnExit = true

        // Remove existing region with same identifier
        if let existingRegion = geofenceRegions[id] {
            locationManager.stopMonitoring(for: existingRegion)
        }

        geofenceRegions[id] = region
        locationManager.startMonitoring(for: region)

        print("✅ Geofence criada: \(name) em (\(latitude), \(longitude)) - raio: \(region.radius)m - total: \(geofenceRegions.count)")
    }

    func removeGeofence(id: String) {
        guard let region = geofenceRegions[id] else { return }

        locationManager.stopMonitoring(for: region)
        geofenceRegions.removeValue(forKey: id)

        print("❌ Geofence removida: \(id)")
    }

    func removeAllGeofences() {
        for (_, region) in geofenceRegions {
            locationManager.stopMonitoring(for: region)
        }
        geofenceRegions.removeAll()
    }

    // MARK: - Utility
    func requestCurrentLocation() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            locationError = "Permissão de localização necessária"
            return
        }

        locationManager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // CRITICAL: Must update @Published properties on main thread for SwiftUI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.authorizationStatus = manager.authorizationStatus

            switch self.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.startLocationUpdates()
                self.locationError = nil
            case .denied, .restricted:
                self.locationError = "Permissão de localização negada"
                self.stopLocationUpdates()
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location
        lastUpdateTime = Date()
        locationError = nil

        print("📍 Localização atualizada: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // Manual geofence detection (works in simulator)
        checkManualGeofences(for: location)
    }

    // MARK: - Manual Geofence Detection (for Simulator)
    private func checkManualGeofences(for location: CLLocation) {
        if geofenceRegions.isEmpty {
            print("⚠️ Nenhuma geofence registrada!")
            return
        }

        for (id, region) in geofenceRegions {
            let regionCenter = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            let distance = location.distance(from: regionCenter)
            let isInside = distance <= region.radius

            let wasInside = currentlyInsideRegions.contains(id)

            if isInside && !wasInside {
                // Entered region
                currentlyInsideRegions.insert(id)
                print("✅ [Manual] Entrou na região: \(id) (distância: \(Int(distance))m)")

                let event = GeofenceEvent.entered(
                    alertId: id,
                    location: region.center,
                    timestamp: Date()
                )
                DispatchQueue.main.async {
                    self.onGeofenceEvent?(event)
                }

            } else if !isInside && wasInside {
                // Exited region
                currentlyInsideRegions.remove(id)
                print("🚶 [Manual] Saiu da região: \(id) (distância: \(Int(distance))m)")

                let event = GeofenceEvent.exited(
                    alertId: id,
                    location: region.center,
                    timestamp: Date()
                )
                DispatchQueue.main.async {
                    self.onGeofenceEvent?(event)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "Erro ao obter localização: \(error.localizedDescription)"
        print("❌ Erro de localização: \(error)")
    }

    // MARK: - Geofencing Events (Native iOS - disabled to avoid duplicates with manual detection)
    // Manual detection in checkManualGeofences() is more reliable in simulator
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Disabled - using manual detection instead
        print("📱 [iOS Nativo] Entrou na região: \(region.identifier) (ignorado)")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Disabled - using manual detection instead
        print("📱 [iOS Nativo] Saiu da região: \(region.identifier) (ignorado)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("❌ Erro no monitoramento de região: \(error)")
        locationError = "Erro ao monitorar região"
    }
}

// MARK: - Geofence Event
enum GeofenceEvent {
    case entered(alertId: String, location: CLLocationCoordinate2D, timestamp: Date)
    case exited(alertId: String, location: CLLocationCoordinate2D, timestamp: Date)
    case sharingPaused(childName: String)
    case sharingResumed(childName: String)
}
