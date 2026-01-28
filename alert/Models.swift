//
//  Models.swift
//  alert
//
//  Phase 1: Mock data models for UI/UX demonstration
//  Phase 2: Extended with real location support and Codable
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - User Mode
enum UserMode: String, Codable {
    case responsavel  // Guardian
    case crianca      // Child
}

// MARK: - Child Status
enum ChildStatus: String, Codable {
    case emCasa = "Em casa"
    case naEscola = "Na escola"
    case compartilhamentoPausado = "Compartilhamento pausado"
    case emTransito = "Em trânsito"
}

// MARK: - Child Model
struct Child: Identifiable, Codable {
    let id: UUID
    var name: String
    var status: ChildStatus
    var lastUpdateMinutes: Int
    var batteryLevel: Int
    var isSharing: Bool

    // Whether the child has accepted the invite (userId is set on backend)
    var hasAcceptedInvite: Bool

    // Phase 2: Real location data
    var lastKnownLatitude: Double?
    var lastKnownLongitude: Double?
    var locationTimestamp: Date?

    var lastKnownLocation: CLLocationCoordinate2D? {
        guard let lat = lastKnownLatitude, let lon = lastKnownLongitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    init(id: UUID = UUID(), name: String, status: ChildStatus, lastUpdateMinutes: Int, batteryLevel: Int, isSharing: Bool, hasAcceptedInvite: Bool = false, lastKnownLatitude: Double? = nil, lastKnownLongitude: Double? = nil, locationTimestamp: Date? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.lastUpdateMinutes = lastUpdateMinutes
        self.batteryLevel = batteryLevel
        self.isSharing = isSharing
        self.hasAcceptedInvite = hasAcceptedInvite
        self.lastKnownLatitude = lastKnownLatitude
        self.lastKnownLongitude = lastKnownLongitude
        self.locationTimestamp = locationTimestamp
    }
}

// MARK: - Schedule Mode
enum ScheduleMode: String, CaseIterable {
    case daily = "Diariamente"
    case weekdays = "Seg a Sex"
    case custom = "Personalizado"
}

// MARK: - Alert Model
struct LocationAlert: Identifiable, Codable {
    let id: UUID
    let childId: String
    let childName: String?
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    var isActive: Bool

    // Schedule fields (optional for backward compatibility)
    var startTime: String?      // "HH:mm" format
    var endTime: String?        // "HH:mm" format
    var scheduleDays: [Int]?    // 0=Sun, 1=Mon, ..., 6=Sat. nil or empty = all days

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var hasSchedule: Bool {
        startTime != nil && endTime != nil
    }

    var scheduleDescription: String? {
        guard let start = startTime, let end = endTime else { return nil }

        let days = scheduleDays ?? []
        let daysText: String

        if days.isEmpty || days.count == 7 {
            daysText = "Diariamente"
        } else if Set(days) == Set([1, 2, 3, 4, 5]) {
            daysText = "Seg a Sex"
        } else {
            let abbrev = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sab"]
            daysText = days.sorted().map { abbrev[$0] }.joined(separator: ", ")
        }

        return "\(daysText) \(start) - \(end)"
    }

    init(id: UUID = UUID(), childId: String, childName: String? = nil, name: String, address: String, latitude: Double, longitude: Double, isActive: Bool, startTime: String? = nil, endTime: String? = nil, scheduleDays: [Int]? = nil) {
        self.id = id
        self.childId = childId
        self.childName = childName
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.isActive = isActive
        self.startTime = startTime
        self.endTime = endTime
        self.scheduleDays = scheduleDays
    }
}

// MARK: - Event Type
enum EventType: String, Codable {
    case chegou    // Arrived
    case saiu      // Left
    case atrasou   // Late
    case pausado   // Paused sharing
    case retomado  // Resumed sharing

    var icon: String {
        switch self {
        case .chegou: return "mappin.circle.fill"
        case .saiu: return "arrow.right.circle.fill"
        case .atrasou: return "clock.fill"
        case .pausado: return "pause.circle.fill"
        case .retomado: return "play.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .chegou: return .green
        case .saiu: return .blue
        case .atrasou: return .orange
        case .pausado: return .gray
        case .retomado: return .green
        }
    }
}

// MARK: - History Event
struct HistoryEvent: Identifiable, Codable {
    let id: UUID
    let childName: String
    let type: EventType
    let location: String
    let timestamp: Date

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var description: String {
        switch type {
        case .chegou:
            return "\(childName) chegou em \(location)"
        case .saiu:
            return "\(childName) saiu de \(location)"
        case .atrasou:
            return "\(childName) atrasou em \(location)"
        case .pausado:
            return "\(childName) pausou compartilhamento"
        case .retomado:
            return "\(childName) retomou compartilhamento"
        }
    }

    init(id: UUID = UUID(), childName: String, type: EventType, location: String, timestamp: Date) {
        self.id = id
        self.childName = childName
        self.type = type
        self.location = location
        self.timestamp = timestamp
    }
}

// MARK: - Mock Data
class MockData {
    static let shared = MockData()

    // Coordenadas base (Barueri/Alphaville)
    private let casaLat = -23.4579436
    private let casaLon = -46.878607
    private let escolaLat = -23.4860111
    private let escolaLon = -46.8365521
    private let avosLat = -23.4650
    private let avosLon = -46.8500

    var children: [Child] = [
        Child(
            name: "Pedro",
            status: .emCasa,
            lastUpdateMinutes: 2,
            batteryLevel: 78,
            isSharing: true,
            lastKnownLatitude: -23.4579436,
            lastKnownLongitude: -46.878607,
            locationTimestamp: Date().addingTimeInterval(-2 * 60)
        ),
        Child(
            name: "Sofia",
            status: .emCasa,
            lastUpdateMinutes: 8,
            batteryLevel: 92,
            isSharing: true,
            lastKnownLatitude: -23.4579436,
            lastKnownLongitude: -46.878607,
            locationTimestamp: Date().addingTimeInterval(-8 * 60)
        )
    ]

    var alerts: [LocationAlert] = [
        LocationAlert(
            childId: "mock-child-1",
            childName: "Pedro",
            name: "Casa",
            address: "Alameda Diamante, 171",
            latitude: -23.4579436,
            longitude: -46.878607,
            isActive: true
        ),
        LocationAlert(
            childId: "mock-child-1",
            childName: "Pedro",
            name: "Escola",
            address: "Colégio Mackenzie",
            latitude: -23.4860111,
            longitude: -46.8365521,
            isActive: true,
            startTime: "07:00",
            endTime: "14:00",
            scheduleDays: [1, 2, 3, 4, 5]
        )
    ]

    var historyEvents: [HistoryEvent] {
        let calendar = Calendar.current
        let now = Date()

        // Histórico de ontem - dia completo do Pedro
        // (hoje começa vazio para simular os eventos em tempo real)
        return [
            // Ontem - Pedro volta para casa
            HistoryEvent(
                childName: "Pedro",
                type: .chegou,
                location: "Casa",
                timestamp: calendar.date(byAdding: .day, value: -1, to: calendar.date(bySettingHour: 12, minute: 35, second: 0, of: now) ?? now) ?? now
            ),
            // Ontem - Pedro sai da escola
            HistoryEvent(
                childName: "Pedro",
                type: .saiu,
                location: "Escola",
                timestamp: calendar.date(byAdding: .day, value: -1, to: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: now) ?? now) ?? now
            ),
            // Ontem - Pedro chega na escola
            HistoryEvent(
                childName: "Pedro",
                type: .chegou,
                location: "Escola",
                timestamp: calendar.date(byAdding: .day, value: -1, to: calendar.date(bySettingHour: 7, minute: 28, second: 0, of: now) ?? now) ?? now
            ),
            // Ontem - Pedro sai de casa
            HistoryEvent(
                childName: "Pedro",
                type: .saiu,
                location: "Casa",
                timestamp: calendar.date(byAdding: .day, value: -1, to: calendar.date(bySettingHour: 7, minute: 05, second: 0, of: now) ?? now) ?? now
            )
        ]
    }

    // Limits for paywall
    let maxFreeAlerts = 3
    let maxFreeChildren = 2
    let maxFreeGuardians = 2
}
