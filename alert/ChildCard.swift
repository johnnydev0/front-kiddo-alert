//
//  ChildCard.swift
//  alert
//

import SwiftUI

struct ChildCard: View {
    let child: Child
    @EnvironmentObject var appState: AppState

    var body: some View {
        // TimelineView updates every 60s so the "X min atrás" ticks automatically
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            cardContent
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                if !child.hasAcceptedInvite {
                    Text("Aguardando aprovação")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(statusColor)

                        if let timestamp = child.locationTimestamp {
                            Text("· \(timeAgo(from: timestamp))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if child.lastUpdateMinutes > 0 {
                            Text("· \(child.lastUpdateMinutes)min atrás")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Battery + chevron
            if child.hasAcceptedInvite {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: batteryIcon)
                            .font(.caption)
                            .foregroundColor(batteryColor)
                        Text("\(child.batteryLevel)%")
                            .font(.caption)
                            .foregroundColor(batteryColor)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var statusIcon: String {
        if !child.hasAcceptedInvite { return "hourglass" }
        switch child.status {
        case .emCasa:                   return "house.fill"
        case .naEscola:                 return "graduationcap.fill"
        case .emTransito:               return "location.fill"
        case .compartilhamentoPausado:  return "pause.circle.fill"
        }
    }

    private var statusColor: Color {
        if !child.hasAcceptedInvite { return .orange }
        switch child.status {
        case .emCasa:                   return .green
        case .naEscola:                 return .blue
        case .emTransito:               return .orange
        case .compartilhamentoPausado:  return .gray
        }
    }

    private var statusText: String {
        switch child.status {
        case .emCasa:                   return "Em casa"
        case .naEscola:                 return "Na escola"
        case .emTransito:               return "Compartilhando"
        case .compartilhamentoPausado:  return "Pausado"
        }
    }

    private var batteryIcon: String {
        switch child.batteryLevel {
        case 0..<10:  return "battery.0percent"
        case 10..<25: return "battery.25percent"
        case 25..<50: return "battery.50percent"
        case 50..<75: return "battery.75percent"
        default:      return "battery.100percent"
        }
    }

    private var batteryColor: Color {
        child.batteryLevel < 20 ? .red : .secondary
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        let minutes = seconds / 60
        let hours = minutes / 60

        if seconds < 60 { return "agora" }
        if minutes < 60 { return "\(minutes)min atrás" }
        if hours < 24 { return "\(hours)h atrás" }
        let fmt = DateFormatter()
        fmt.dateFormat = "dd/MM HH:mm"
        fmt.locale = Locale(identifier: "pt_BR")
        return fmt.string(from: date)
    }
}
