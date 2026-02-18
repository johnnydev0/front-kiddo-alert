//
//  AppState.swift
//  alert
//
//  Global app state management
//  Phase 1: Mock data
//  Phase 2: Real location services integration
//  Phase 3: Backend API integration
//

import SwiftUI
import Combine
import CoreLocation
import UIKit

@MainActor
class AppState: ObservableObject {
    @Published var userMode: UserMode = .responsavel
    @Published var showingSplash = true
    @Published var selectedChild: Child?
    @Published var currentChildName = "Pedro" // For child mode

    // Navigation
    @Published var navigationPath = NavigationPath()

    // Phase 3: API data
    @Published var alerts: [LocationAlert] = []
    @Published var children: [Child] = []
    @Published var historyEvents: [HistoryEvent] = []

    // Phase 3: Loading and error states
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Phase 3: Auth state
    @Published var needsAuth = false
    @Published var needsModeSelection = false
    @Published var needsProfileSetup = false

    // For child mode: guardians who can see location
    @Published var guardians: [APIGuardian] = []

    // Mock data (kept for offline/fallback)
    let mockData = MockData.shared

    // Managers
    let locationManager = LocationManager()
    let authManager = AuthManager.shared
    private let dataManager = DataManager.shared
    private let api = APIService.shared

    private var cancellables = Set<AnyCancellable>()
    private var locationPollingTimer: Timer?

    init() {
        setupLocationManager()
        setupAuthObserver()
        loadData()
    }

    // MARK: - Setup
    private func setupLocationManager() {
        // Listen for geofence events
        locationManager.onGeofenceEvent = { [weak self] event in
            Task { @MainActor in
                self?.handleGeofenceEvent(event)
            }
        }

        // Observe location updates
        locationManager.$currentLocation
            .sink { [weak self] location in
                Task { @MainActor in
                    await self?.handleLocationUpdate(location)
                }
            }
            .store(in: &cancellables)
    }

    private func setupAuthObserver() {
        // Observe auth state changes
        authManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleAuthStateChange(state)
            }
            .store(in: &cancellables)

        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if let user = user {
                    self?.userMode = user.mode == "child" ? .crianca : .responsavel
                    self?.dataManager.saveUserMode(self?.userMode ?? .responsavel)
                }
            }
            .store(in: &cancellables)
    }

    private func handleAuthStateChange(_ state: AuthState) {
        switch state {
        case .unknown:
            break
        case .unauthenticated:
            needsAuth = true
            needsModeSelection = true
            needsProfileSetup = false
        case .authenticated(let user):
            needsAuth = false
            needsModeSelection = false

            // Request notification permissions after authentication
            Task {
                await NotificationManager.shared.requestPermission()
            }

            if user.mode != "child" {
                // Guardian mode: check if profile setup is needed (name is empty)
                needsProfileSetup = user.name == nil || user.name?.isEmpty == true

                if !needsProfileSetup {
                    Task {
                        await loadDataFromAPI()
                    }
                }
            } else {
                // Child mode: no profile setup needed, guardian already set the name
                needsProfileSetup = false
                print("📱 Usuário criança autenticado - carregando responsáveis")
                Task {
                    await loadGuardians()
                }
            }
        }
    }

    private func loadData() {
        // Load persisted data for offline support
        alerts = dataManager.loadAlerts()
        children = dataManager.loadChildren()
        historyEvents = dataManager.loadHistoryEvents()
        userMode = dataManager.loadUserMode()

        // If no cached data, use mock data for first launch
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

        // Create geofences for all active alerts
        print("📋 Criando geofences para \(alerts.count) alertas...")
        for alert in alerts where alert.isActive {
            print("   - \(alert.name): (\(alert.latitude), \(alert.longitude))")
            createGeofence(for: alert)
        }

        // Check auth state
        Task {
            await authManager.checkAuthState()
        }
    }

    // MARK: - API Data Loading

    func loadDataFromAPI() async {
        guard authManager.isAuthenticated else { return }

        // Only guardians can load children, alerts, and history
        // Children don't need this data
        guard authManager.userMode == .responsavel else {
            print("📱 Modo criança - não carregando dados de responsável")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Load children and alerts in parallel
            async let childrenTask = api.getChildren()
            async let alertsTask = api.getAlerts()
            async let historyTask = api.getHistory()

            let (apiChildren, apiAlerts, historyResponse) = try await (childrenTask, alertsTask, historyTask)

            // Convert API models to local models
            children = apiChildren.map { convertAPIChildToChild($0) }
            alerts = apiAlerts.map { convertAPIAlertToLocationAlert($0) }
            historyEvents = historyResponse.events.map { convertAPIEventToHistoryEvent($0) }

            // Cache locally
            dataManager.saveChildren(children)
            dataManager.saveAlerts(alerts)
            dataManager.saveHistoryEvents(historyEvents)

            // Update geofences
            locationManager.removeAllGeofences()
            for alert in alerts where alert.isActive {
                createGeofence(for: alert)
            }

            print("✅ Dados carregados da API: \(children.count) crianças, \(alerts.count) alertas")
        } catch {
            print("❌ Erro ao carregar dados da API: \(error)")
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
            // Keep using cached/mock data
        }

        isLoading = false

        // Start polling for location updates in guardian mode
        startLocationPolling()
    }

    // MARK: - Location Polling (Guardian Mode)

    func startLocationPolling() {
        stopLocationPolling()
        guard authManager.userMode == .responsavel else { return }

        locationPollingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshChildren()
            }
        }
        print("🔄 Polling de localização iniciado (30s)")
    }

    func stopLocationPolling() {
        locationPollingTimer?.invalidate()
        locationPollingTimer = nil
    }

    // MARK: - Model Converters

    private func convertAPIChildToChild(_ apiChild: APIChild) -> Child {
        let timestamp: Date?
        if let timeString = apiChild.lastUpdateTime {
            timestamp = ISO8601DateFormatter().date(from: timeString)
        } else {
            timestamp = nil
        }

        let minutesSinceUpdate: Int
        if let ts = timestamp {
            minutesSinceUpdate = Int(Date().timeIntervalSince(ts) / 60)
        } else {
            minutesSinceUpdate = 0
        }

        return Child(
            id: UUID(uuidString: apiChild.id) ?? UUID(),
            name: apiChild.name,
            status: apiChild.isSharing ? .emTransito : .compartilhamentoPausado,
            lastUpdateMinutes: minutesSinceUpdate,
            batteryLevel: apiChild.batteryLevel ?? 100,
            isSharing: apiChild.isSharing,
            hasAcceptedInvite: apiChild.userId != nil,
            lastKnownLatitude: apiChild.lastLatitude,
            lastKnownLongitude: apiChild.lastLongitude,
            locationTimestamp: timestamp
        )
    }

    private func convertAPIAlertToLocationAlert(_ apiAlert: APIAlert) -> LocationAlert {
        return LocationAlert(
            id: UUID(uuidString: apiAlert.id) ?? UUID(),
            childId: apiAlert.child?.id ?? "",
            childName: apiAlert.child?.name,
            name: apiAlert.name,
            address: apiAlert.address ?? "",
            latitude: apiAlert.latitude,
            longitude: apiAlert.longitude,
            isActive: apiAlert.isActive,
            startTime: apiAlert.startTime,
            endTime: apiAlert.endTime,
            scheduleDays: apiAlert.scheduleDays
        )
    }

    private func convertAPIEventToHistoryEvent(_ apiEvent: APIHistoryEvent) -> HistoryEvent {
        let eventType: EventType
        switch apiEvent.type {
        case "arrived": eventType = .chegou
        case "left": eventType = .saiu
        case "paused": eventType = .pausado
        case "resumed": eventType = .retomado
        default: eventType = .chegou
        }

        let timestamp = ISO8601DateFormatter().date(from: apiEvent.timestamp) ?? Date()

        return HistoryEvent(
            id: UUID(uuidString: apiEvent.id) ?? UUID(),
            childName: apiEvent.child?.name ?? "",
            type: eventType,
            location: apiEvent.location ?? apiEvent.alert?.name ?? "",
            timestamp: timestamp
        )
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

    // MARK: - Authentication

    func authenticateAsGuardian() async {
        do {
            try await authManager.authenticateDevice(mode: .responsavel)
            userMode = .responsavel
            dataManager.saveUserMode(userMode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func authenticateAsChild() async {
        do {
            try await authManager.authenticateDevice(mode: .crianca)
            userMode = .crianca
            dataManager.saveUserMode(userMode)
            locationManager.startLocationUpdates()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func authenticateAsChildWithInvite(code: String) async throws {
        // 1. First, verify the invite is valid
        let inviteDetails = try await api.getInviteDetails(token: code)
        print("✅ Convite válido: \(inviteDetails.invite.type)")

        // 2. Authenticate as child WITHOUT publishing state change yet.
        //    Publishing state would set needsModeSelection=false, causing
        //    ContentView to dismiss ModeSelectionView/ChildInviteView and
        //    cancel this Task before acceptInvite can run.
        let user = try await authManager.authenticateDeviceSilently(mode: .crianca)

        // 3. Accept the invite (links child to guardian) — must complete before navigation
        _ = try await api.acceptInvite(token: code)
        print("✅ Convite aceito, criança vinculada ao responsável")

        // 4. Update local state
        userMode = .crianca
        if let childName = inviteDetails.childName {
            currentChildName = childName
        }
        dataManager.saveUserMode(userMode)

        // 5. Now publish auth state (triggers navigation to ChildModeView)
        authManager.publishAuthState(user)

        // 6. Start location updates
        locationManager.startLocationUpdates()

        print("✅ Autenticado como criança: \(currentChildName)")
    }

    func logout() async {
        await authManager.logout()
        stopLocationPolling()
        needsAuth = true
        needsModeSelection = true
        needsProfileSetup = false
        guardians = []

        // Clear local data
        children = []
        alerts = []
        historyEvents = []
        locationManager.removeAllGeofences()
    }

    // MARK: - Profile Setup

    func completeProfileSetup(name: String, email: String) async throws {
        try await authManager.updateUserProfile(name: name, email: email)
        needsProfileSetup = false

        // Now load data based on user mode
        if userMode == .responsavel {
            await loadDataFromAPI()
        } else {
            await loadGuardians()
            locationManager.startLocationUpdates()
        }
    }

    // MARK: - Guardians (for child mode)

    func loadGuardians() async {
        do {
            guardians = try await api.getMyGuardians()
            print("✅ Responsáveis carregados: \(guardians.count)")
        } catch {
            print("❌ Erro ao carregar responsáveis: \(error)")
            // Use empty array - guardians endpoint might not exist yet
            guardians = []
        }
    }

    // MARK: - Alert Management

    func addAlert(_ alert: LocationAlert) {
        print("➕ Adicionando alerta: \(alert.name) para criança: \(alert.childId)")

        // Add locally first for immediate UI update
        alerts.append(alert)
        dataManager.saveAlerts(alerts)

        if alert.isActive {
            createGeofence(for: alert)
        }

        // Sync with API
        if authManager.isAuthenticated, !alert.childId.isEmpty {
            Task {
                do {
                    let apiAlert = try await api.createAlert(
                        childId: alert.childId,
                        name: alert.name,
                        address: alert.address,
                        latitude: alert.latitude,
                        longitude: alert.longitude,
                        radius: 100,
                        startTime: alert.startTime,
                        endTime: alert.endTime,
                        scheduleDays: alert.scheduleDays
                    )
                    print("✅ Alerta criado na API: \(apiAlert.id)")

                    // Update local alert with API ID
                    if let index = alerts.firstIndex(where: { $0.name == alert.name && $0.latitude == alert.latitude }) {
                        alerts[index] = convertAPIAlertToLocationAlert(apiAlert)
                        dataManager.saveAlerts(alerts)
                    }

                    await authManager.refreshLimits()
                } catch {
                    print("❌ Erro ao criar alerta na API: \(error)")
                    errorMessage = (error as? APIError)?.localizedDescription
                }
            }
        }

        objectWillChange.send()
    }

    func removeAlert(_ alert: LocationAlert) {
        alerts.removeAll { $0.id == alert.id }
        dataManager.saveAlerts(alerts)
        locationManager.removeGeofence(id: alert.id.uuidString)

        // Sync with API
        if authManager.isAuthenticated {
            Task {
                do {
                    try await api.deleteAlert(id: alert.id.uuidString.lowercased())
                    print("✅ Alerta removido da API")
                    await authManager.refreshLimits()
                } catch {
                    print("❌ Erro ao remover alerta da API: \(error)")
                }
            }
        }
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

            // Sync with API
            if authManager.isAuthenticated {
                Task {
                    do {
                        _ = try await api.updateAlert(
                            id: alert.id.uuidString.lowercased(),
                            name: alert.name,
                            isActive: alert.isActive,
                            address: alert.address,
                            latitude: alert.latitude,
                            longitude: alert.longitude,
                            startTime: alert.startTime,
                            endTime: alert.endTime,
                            scheduleDays: alert.scheduleDays
                        )
                        print("✅ Alerta atualizado na API")
                    } catch {
                        print("❌ Erro ao atualizar alerta na API: \(error)")
                    }
                }
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

    func addChild(name: String) async throws -> (Child, String)? {
        guard authManager.isAuthenticated else {
            // Offline mode - just add locally
            let child = Child(
                name: name,
                status: .compartilhamentoPausado,
                lastUpdateMinutes: 0,
                batteryLevel: 100,
                isSharing: false
            )
            children.append(child)
            dataManager.saveChildren(children)
            return nil
        }

        do {
            let response = try await api.createChild(name: name)

            let child = Child(
                id: UUID(uuidString: response.child.id) ?? UUID(),
                name: response.child.name,
                status: .compartilhamentoPausado,
                lastUpdateMinutes: 0,
                batteryLevel: 100,
                isSharing: false
            )

            children.append(child)
            dataManager.saveChildren(children)

            await authManager.refreshLimits()

            print("✅ Criança adicionada: \(name), token: \(response.inviteToken)")
            return (child, response.inviteToken)
        } catch {
            print("❌ Erro ao adicionar criança: \(error)")
            errorMessage = (error as? APIError)?.localizedDescription
            throw error
        }
    }

    func removeChild(_ child: Child) {
        children.removeAll { $0.id == child.id }
        dataManager.saveChildren(children)

        // Remove associated alerts
        let childAlerts = alerts.filter { _ in true } // In real app, filter by childId
        for alert in childAlerts {
            removeAlert(alert)
        }

        // Sync with API
        if authManager.isAuthenticated {
            Task {
                do {
                    try await api.deleteChild(id: child.id.uuidString)
                    print("✅ Criança removida da API")
                    await authManager.refreshLimits()
                } catch {
                    print("❌ Erro ao remover criança da API: \(error)")
                }
            }
        }
    }

    func updateChild(_ child: Child) {
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
            dataManager.saveChildren(children)
        }
    }

    func updateChildName(child: Child, newName: String) async {
        // Update locally first for immediate UI feedback
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            var updatedChild = children[index]
            updatedChild.name = newName
            children[index] = updatedChild
            dataManager.saveChildren(children)
        }

        // Sync with API
        if authManager.isAuthenticated {
            do {
                _ = try await api.updateChild(id: child.id.uuidString, name: newName)
                print("✅ Nome da criança atualizado na API: \(newName)")
            } catch {
                print("❌ Erro ao atualizar nome da criança na API: \(error)")
                errorMessage = (error as? APIError)?.localizedDescription
            }
        }
    }

    func refreshChildren() async {
        guard authManager.isAuthenticated else { return }
        guard authManager.userMode == .responsavel else { return }

        do {
            let apiChildren = try await api.getChildren()
            children = apiChildren.map { convertAPIChildToChild($0) }
            dataManager.saveChildren(children)
        } catch {
            print("❌ Erro ao atualizar crianças: \(error)")
        }
    }

    func generateInviteCode(for child: Child) async throws -> String {
        guard authManager.isAuthenticated else {
            throw APIError.unauthorized
        }

        let response = try await api.createChildInvite(childId: child.id.uuidString)
        print("✅ Novo código de convite (criança) gerado: \(response.inviteToken)")
        return response.inviteToken
    }

    func generateGuardianInviteCode(for child: Child) async throws -> String {
        guard authManager.isAuthenticated else {
            throw APIError.unauthorized
        }

        let response = try await api.createGuardianInvite(childId: child.id.uuidString.lowercased())
        print("✅ Novo código de convite (responsável) gerado: \(response.token)")
        return response.token
    }

    func acceptGuardianInvite(code: String) async throws {
        // 1. Verify invite details
        let details = try await api.getInviteDetails(token: code)
        guard details.invite.type == "add_guardian" else {
            throw APIError.serverError(code: "INVALID_TYPE", message: "Este código não é um convite de responsável")
        }

        // 2. Accept the invite
        let result = try await api.acceptInvite(token: code)
        print("✅ Convite de responsável aceito: \(result.message)")

        // 3. Reload data to show the new child
        await loadDataFromAPI()
        await authManager.refreshLimits()
    }

    // MARK: - Location Updates
    private func handleLocationUpdate(_ location: CLLocation?) async {
        guard let location = location else { return }

        // In child mode: update location and send to API
        if userMode == .crianca {
            // Update local state
            if let childIndex = children.firstIndex(where: { $0.name == currentChildName }) {
                var updatedChild = children[childIndex]
                updatedChild.lastKnownLatitude = location.coordinate.latitude
                updatedChild.lastKnownLongitude = location.coordinate.longitude
                updatedChild.locationTimestamp = Date()
                updatedChild.lastUpdateMinutes = 0
                updateChild(updatedChild)
            }

            // Send to API
            if authManager.isAuthenticated {
                do {
                    let batteryLevel = await getBatteryLevel()
                    let response = try await api.updateLocation(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        batteryLevel: batteryLevel
                    )

                    if let triggered = response.triggeredAlerts, !triggered.isEmpty {
                        print("🔔 Alertas disparados: \(triggered)")
                    }
                } catch {
                    print("❌ Erro ao enviar localização: \(error)")
                }
            }
        }
    }

    private func getBatteryLevel() async -> Int {
        await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = UIDevice.current.batteryLevel
            return level >= 0 ? Int(level * 100) : 100
        }
    }

    // MARK: - Location Sharing Control (Child Mode)

    func pauseLocationSharing() async {
        guard userMode == .crianca else { return }

        locationManager.stopLocationUpdates()

        if authManager.isAuthenticated {
            do {
                try await api.pauseLocationSharing()
                print("✅ Compartilhamento pausado")
            } catch {
                print("❌ Erro ao pausar compartilhamento: \(error)")
            }
        }

        // Update local state
        if let childIndex = children.firstIndex(where: { $0.name == currentChildName }) {
            var updatedChild = children[childIndex]
            updatedChild.isSharing = false
            updatedChild.status = .compartilhamentoPausado
            updateChild(updatedChild)
        }

        // Add history event
        let event = HistoryEvent(
            childName: currentChildName,
            type: .pausado,
            location: "",
            timestamp: Date()
        )
        addHistoryEvent(event)
    }

    func resumeLocationSharing() async {
        guard userMode == .crianca else { return }

        locationManager.startLocationUpdates()

        if authManager.isAuthenticated {
            do {
                try await api.resumeLocationSharing()
                print("✅ Compartilhamento retomado")
            } catch {
                print("❌ Erro ao retomar compartilhamento: \(error)")
            }
        }

        // Update local state
        if let childIndex = children.firstIndex(where: { $0.name == currentChildName }) {
            var updatedChild = children[childIndex]
            updatedChild.isSharing = true
            updatedChild.status = .emTransito
            updateChild(updatedChild)
        }

        // Add history event
        let event = HistoryEvent(
            childName: currentChildName,
            type: .retomado,
            location: "",
            timestamp: Date()
        )
        addHistoryEvent(event)
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
