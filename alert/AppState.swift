//
//  AppState.swift
//  alert
//
//  Global app state management
//  Phase 1: Mock data
//  Phase 2: Real location services integration
//

import SwiftUI
import Combine
import CoreLocation

class AppState: ObservableObject {
    @Published var userMode: UserMode = .responsavel
    @Published var showingSplash = true
    @Published var selectedChild: Child?
    @Published var currentChildName = "Pedro" // For child mode

    // Navigation
    @Published var navigationPath = NavigationPath()

    // Phase 2: Real data
    @Published var alerts: [LocationAlert] = []
    @Published var children: [Child] = []
    @Published var historyEvents: [HistoryEvent] = []

    // Mock data (kept for backward compatibility during migration)
    let mockData = MockData.shared

    // Phase 2: Managers
    let locationManager = LocationManager()
    private let dataManager = DataManager.shared

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupLocationManager()
        loadData()
    }

    // MARK: - Setup
    private func setupLocationManager() {
        // Listen for geofence events
        locationManager.onGeofenceEvent = { [weak self] event in
            self?.handleGeofenceEvent(event)
        }

        // Observe location updates
        locationManager.$currentLocation
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }

    private func loadData() {
        // Load persisted data
        alerts = dataManager.loadAlerts()
        children = dataManager.loadChildren()
        historyEvents = dataManager.loadHistoryEvents()
        userMode = dataManager.loadUserMode()

        // If no data, use mock data for first launch
        if children.isEmpty {
            children = mockData.children
            dataManager.saveChildren(children)
        }

        if alerts.isEmpty {
            alerts = mockData.alerts
            dataManager.saveAlerts(alerts)
        }

        if historyEvents.isEmpty {
            historyEvents = mockData.historyEvents
            dataManager.saveHistoryEvents(historyEvents)
        }

        // Always create geofences for all active alerts on startup
        print("📋 Criando geofences para \(alerts.count) alertas...")
        for alert in alerts where alert.isActive {
            print("   - \(alert.name): (\(alert.latitude), \(alert.longitude))")
            createGeofence(for: alert)
        }
    }

    // MARK: - Navigation
    func finishSplash() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showingSplash = false
            }
        }
    }

    func toggleMode() {
        userMode = userMode == .responsavel ? .crianca : .responsavel
        dataManager.saveUserMode(userMode)

        // Start location updates when switching to child mode
        if userMode == .crianca {
            locationManager.startLocationUpdates()
        }
    }

    func startLocationTracking() {
        locationManager.requestLocationPermission()
        locationManager.startLocationUpdates()
    }

    // Reset all data to mock data (for testing)
    func resetToMockData() {
        dataManager.clearAllData()
        children = mockData.children
        alerts = mockData.alerts
        historyEvents = mockData.historyEvents
        userMode = .responsavel

        dataManager.saveChildren(children)
        dataManager.saveAlerts(alerts)
        dataManager.saveHistoryEvents(historyEvents)
        dataManager.saveUserMode(userMode)

        // Recreate all geofences
        locationManager.removeAllGeofences()
        for alert in alerts where alert.isActive {
            createGeofence(for: alert)
        }

        print("🔄 Dados resetados para mock data")
    }

    // MARK: - Alert Management
    func addAlert(_ alert: LocationAlert) {
        print("➕ Adicionando alerta: \(alert.name)")
        print("   Alertas antes: \(alerts.count)")
        alerts.append(alert)
        print("   Alertas depois: \(alerts.count)")
        dataManager.saveAlerts(alerts)

        if alert.isActive {
            createGeofence(for: alert)
        }

        // Force UI update
        objectWillChange.send()
    }

    func removeAlert(_ alert: LocationAlert) {
        alerts.removeAll { $0.id == alert.id }
        dataManager.saveAlerts(alerts)
        locationManager.removeGeofence(id: alert.id.uuidString)
    }

    func updateAlert(_ alert: LocationAlert) {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index] = alert
            dataManager.saveAlerts(alerts)

            // Update geofence
            if alert.isActive {
                createGeofence(for: alert)
            } else {
                locationManager.removeGeofence(id: alert.id.uuidString)
            }
        }
    }

    private func createGeofence(for alert: LocationAlert) {
        locationManager.addGeofence(
            id: alert.id.uuidString,
            name: alert.name,
            latitude: alert.latitude,
            longitude: alert.longitude
        )
    }

    // MARK: - Child Management
    func updateChild(_ child: Child) {
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
            dataManager.saveChildren(children)
        }
    }

    // MARK: - Location Updates
    private func handleLocationUpdate(_ location: CLLocation?) {
        guard let location = location else { return }

        // In child mode: update the current child's location
        if userMode == .crianca,
           let childIndex = children.firstIndex(where: { $0.name == currentChildName }) {
            var updatedChild = children[childIndex]
            updatedChild.lastKnownLatitude = location.coordinate.latitude
            updatedChild.lastKnownLongitude = location.coordinate.longitude
            updatedChild.locationTimestamp = Date()
            updatedChild.lastUpdateMinutes = 0
            updateChild(updatedChild)
        } else {
            // In responsável mode: update all children who are sharing
            // (In production this would come from backend, but for Phase 2 we simulate with device location)
            for (index, child) in children.enumerated() where child.isSharing {
                var updatedChild = children[index]
                // Update location with current device location
                updatedChild.lastKnownLatitude = location.coordinate.latitude
                updatedChild.lastKnownLongitude = location.coordinate.longitude
                updatedChild.locationTimestamp = Date()
                updatedChild.lastUpdateMinutes = 0
                children[index] = updatedChild
            }
            dataManager.saveChildren(children)
        }
    }

    // MARK: - Geofence Events
    private func handleGeofenceEvent(_ event: GeofenceEvent) {
        let historyEvent: HistoryEvent

        switch event {
        case .entered(let alertId, _, let timestamp):
            guard let alert = alerts.first(where: { $0.id.uuidString == alertId }) else { return }

            historyEvent = HistoryEvent(
                childName: currentChildName,
                type: .chegou,
                location: alert.name,
                timestamp: timestamp
            )

            // Update child status
            if let childIndex = children.firstIndex(where: { $0.name == currentChildName }) {
                var updatedChild = children[childIndex]
                updatedChild.status = statusForLocation(alert.name)
                updateChild(updatedChild)
            }

        case .exited(let alertId, _, let timestamp):
            guard let alert = alerts.first(where: { $0.id.uuidString == alertId }) else { return }

            historyEvent = HistoryEvent(
                childName: currentChildName,
                type: .saiu,
                location: alert.name,
                timestamp: timestamp
            )

            // Update child status
            if let childIndex = children.firstIndex(where: { $0.name == currentChildName }) {
                var updatedChild = children[childIndex]
                updatedChild.status = .emTransito
                updateChild(updatedChild)
            }

        case .sharingPaused(let childName):
            historyEvent = HistoryEvent(
                childName: childName,
                type: .pausado,
                location: "",
                timestamp: Date()
            )

            // Update child sharing status
            if let childIndex = children.firstIndex(where: { $0.name == childName }) {
                var updatedChild = children[childIndex]
                updatedChild.isSharing = false
                updatedChild.status = .compartilhamentoPausado
                updateChild(updatedChild)
            }

        case .sharingResumed(let childName):
            historyEvent = HistoryEvent(
                childName: childName,
                type: .retomado,
                location: "",
                timestamp: Date()
            )

            // Update child sharing status
            if let childIndex = children.firstIndex(where: { $0.name == childName }) {
                var updatedChild = children[childIndex]
                updatedChild.isSharing = true
                updateChild(updatedChild)
            }
        }

        addHistoryEvent(historyEvent)
    }

    private func statusForLocation(_ locationName: String) -> ChildStatus {
        switch locationName.lowercased() {
        case "casa":
            return .emCasa
        case "escola":
            return .naEscola
        default:
            return .emTransito
        }
    }

    // MARK: - History Management
    func addHistoryEvent(_ event: HistoryEvent) {
        historyEvents.insert(event, at: 0)
        dataManager.saveHistoryEvents(historyEvents)
    }
}
