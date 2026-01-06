//
//  Models.swift
//  alert
//
//  Phase 1: Mock data models for UI/UX demonstration
//

import Foundation
import SwiftUI

// MARK: - User Mode
enum UserMode {
    case responsavel  // Guardian
    case crianca      // Child
}

// MARK: - Child Status
enum ChildStatus: String {
    case emCasa = "Em casa"
    case naEscola = "Na escola"
    case compartilhamentoPausado = "Compartilhamento pausado"
    case emTransito = "Em trânsito"
}

// MARK: - Child Model
struct Child: Identifiable {
    let id = UUID()
    let name: String
    var status: ChildStatus
    var lastUpdateMinutes: Int
    var batteryLevel: Int
    var isSharing: Bool
}

// MARK: - Alert Model
struct LocationAlert: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let expectedTime: String?
    let latitude: Double
    let longitude: Double
}

// MARK: - Event Type
enum EventType {
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
struct HistoryEvent: Identifiable {
    let id = UUID()
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
            isSharing: true
        ),
        Child(
            name: "Maria",
            status: .emCasa,
            lastUpdateMinutes: 15,
            batteryLevel: 45,
            isSharing: true
        )
    ]

    var alerts: [LocationAlert] = [
        LocationAlert(
            name: "Escola",
            address: "Rua das Flores, 123",
            expectedTime: "08:00",
            latitude: -23.5505,
            longitude: -46.6333
        ),
        LocationAlert(
            name: "Casa",
            address: "Av. Paulista, 1000",
            expectedTime: nil,
            latitude: -23.5489,
            longitude: -46.6388
        )
    ]

    var historyEvents: [HistoryEvent] {
        let now = Date()
        return [
            HistoryEvent(
                childName: "João",
                type: .chegou,
                location: "Escola",
                timestamp: now.addingTimeInterval(-3 * 60)
            ),
            HistoryEvent(
                childName: "Maria",
                type: .saiu,
                location: "Casa da Vovó",
                timestamp: now.addingTimeInterval(-45 * 60)
            ),
            HistoryEvent(
                childName: "João",
                type: .saiu,
                location: "Casa",
                timestamp: now.addingTimeInterval(-35 * 60)
            ),
            HistoryEvent(
                childName: "Maria",
                type: .chegou,
                location: "Casa",
                timestamp: Date().addingTimeInterval(-24 * 60 * 60) // Yesterday
            )
        ]
    }

    // Limits for paywall
    let maxFreeAlerts = 3
    let maxFreeChildren = 10
    let maxFreeGuardians = 2
}
