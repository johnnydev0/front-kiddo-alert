//
//  DataManager.swift
//  alert
//
//  Phase 2: Local data persistence using UserDefaults
//

import Foundation
import CoreLocation

class DataManager {
    static let shared = DataManager()

    // MARK: - Keys
    private enum Keys {
        static let alerts = "saved_alerts"
        static let historyEvents = "history_events"
        static let children = "children"
        static let userMode = "user_mode"
        static let hasSeenPermissionExplanation = "has_seen_permission_explanation"
    }

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Alerts
    func saveAlerts(_ alerts: [LocationAlert]) {
        do {
            let data = try encoder.encode(alerts)
            defaults.set(data, forKey: Keys.alerts)
        } catch {
            print("❌ Erro ao salvar alertas: \(error)")
        }
    }

    func loadAlerts() -> [LocationAlert] {
        guard let data = defaults.data(forKey: Keys.alerts) else {
            return []
        }

        do {
            return try decoder.decode([LocationAlert].self, from: data)
        } catch {
            print("❌ Erro ao carregar alertas: \(error)")
            return []
        }
    }

    func addAlert(_ alert: LocationAlert) {
        var alerts = loadAlerts()
        alerts.append(alert)
        saveAlerts(alerts)
    }

    func removeAlert(_ alert: LocationAlert) {
        var alerts = loadAlerts()
        alerts.removeAll { $0.id == alert.id }
        saveAlerts(alerts)
    }

    func updateAlert(_ alert: LocationAlert) {
        var alerts = loadAlerts()
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index] = alert
            saveAlerts(alerts)
        }
    }

    // MARK: - History Events
    func saveHistoryEvents(_ events: [HistoryEvent]) {
        do {
            let data = try encoder.encode(events)
            defaults.set(data, forKey: Keys.historyEvents)
        } catch {
            print("❌ Erro ao salvar histórico: \(error)")
        }
    }

    func loadHistoryEvents() -> [HistoryEvent] {
        guard let data = defaults.data(forKey: Keys.historyEvents) else {
            return []
        }

        do {
            return try decoder.decode([HistoryEvent].self, from: data)
        } catch {
            print("❌ Erro ao carregar histórico: \(error)")
            return []
        }
    }

    func addHistoryEvent(_ event: HistoryEvent) {
        var events = loadHistoryEvents()
        events.insert(event, at: 0) // Add at beginning (most recent first)
        saveHistoryEvents(events)
    }

    func clearOldHistoryEvents(olderThan days: Int = 30) {
        var events = loadHistoryEvents()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        events.removeAll { $0.timestamp < cutoffDate }
        saveHistoryEvents(events)
    }

    // MARK: - Children
    func saveChildren(_ children: [Child]) {
        do {
            let data = try encoder.encode(children)
            defaults.set(data, forKey: Keys.children)
        } catch {
            print("❌ Erro ao salvar crianças: \(error)")
        }
    }

    func loadChildren() -> [Child] {
        guard let data = defaults.data(forKey: Keys.children) else {
            return []
        }

        do {
            return try decoder.decode([Child].self, from: data)
        } catch {
            print("❌ Erro ao carregar crianças: \(error)")
            return []
        }
    }

    func updateChild(_ child: Child) {
        var children = loadChildren()
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
            saveChildren(children)
        }
    }

    // MARK: - User Mode
    func saveUserMode(_ mode: UserMode) {
        let modeString = mode == .responsavel ? "responsavel" : "crianca"
        defaults.set(modeString, forKey: Keys.userMode)
    }

    func loadUserMode() -> UserMode {
        guard let modeString = defaults.string(forKey: Keys.userMode) else {
            return .responsavel // Default
        }
        return modeString == "crianca" ? .crianca : .responsavel
    }

    // MARK: - Permission Explanation
    var hasSeenPermissionExplanation: Bool {
        get { defaults.bool(forKey: Keys.hasSeenPermissionExplanation) }
        set { defaults.set(newValue, forKey: Keys.hasSeenPermissionExplanation) }
    }

    // MARK: - Clear All Data (for testing/reset)
    func clearAllData() {
        defaults.removeObject(forKey: Keys.alerts)
        defaults.removeObject(forKey: Keys.historyEvents)
        defaults.removeObject(forKey: Keys.children)
        defaults.removeObject(forKey: Keys.userMode)
        defaults.removeObject(forKey: Keys.hasSeenPermissionExplanation)
    }
}
