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
    let name: String
    var status: ChildStatus
    var lastUpdateMinutes: Int
    var batteryLevel: Int
    var isSharing: Bool

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

    init(id: UUID = UUID(), name: String, status: ChildStatus, lastUpdateMinutes: Int, batteryLevel: Int, isSharing: Bool, lastKnownLatitude: Double? = nil, lastKnownLongitude: Double? = nil, locationTimestamp: Date? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.lastUpdateMinutes = lastUpdateMinutes
        self.batteryLevel = batteryLevel
        self.isSharing = isSharing
        self.lastKnownLatitude = lastKnownLatitude
        self.lastKnownLongitude = lastKnownLongitude
        self.locationTimestamp = locationTimestamp
    }
}

// MARK: - Alert Model
struct LocationAlert: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String
    let expectedTime: String?
    let latitude: Double
    let longitude: Double
    var isActive: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(id: UUID = UUID(), name: String, address: String, expectedTime: String?, latitude: Double, longitude: Double, isActive: Bool) {
        self.id = id
        self.name = name
        self.address = address
        self.expectedTime = expectedTime
        self.latitude = latitude
        self.longitude = longitude
        self.isActive = isActive
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

    var children: [Child] = [
        Child(
            name: "João",
            status: .naEscola,
            lastUpdateMinutes: 3,
            batteryLevel: 87,
            isSharing: true,
            lastKnownLatitude: -23.5505,
            lastKnownLongitude: -46.6333,
            locationTimestamp: Date().addingTimeInterval(-3 * 60)
        ),
        Child(
            name: "Maria",
            status: .emCasa,
            lastUpdateMinutes: 15,
            batteryLevel: 45,
            isSharing: true,
            lastKnownLatitude: -23.5489,
            lastKnownLongitude: -46.6388,
            locationTimestamp: Date().addingTimeInterval(-15 * 60)
        )
    ]

    var alerts: [LocationAlert] = []

    var historyEvents: [HistoryEvent] {
        return []
    }

    // Limits for paywall
    let maxFreeAlerts = 3
    let maxFreeChildren = 10
    let maxFreeGuardians = 2
}
