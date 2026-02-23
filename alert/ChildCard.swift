import SwiftUI

// MARK: - StatusBadge (shared with ChildDetailView)
struct StatusBadge: View {
    let child: Child

    private var label: String {
        if !child.hasAcceptedInvite { return "Aguardando" }
        switch child.status {
        case .compartilhamentoPausado: return "Pausado"
        case .emCasa:                  return "Em casa"
        case .naEscola:                return "Na escola"
        case .emTransito:              return "Compartilhando"
        }
    }

    private var dotColor: Color {
        if !child.hasAcceptedInvite { return .orange }
        switch child.status {
        case .compartilhamentoPausado: return Color(.systemGray)
        case .emCasa, .naEscola, .emTransito: return .green
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(dotColor).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(dotColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(dotColor.opacity(0.12)))
    }
}

// MARK: - ChildCard
struct ChildCard: View {
    let child: Child
    @EnvironmentObject var appState: AppState

    private var avatarColor: Color {
        let colors: [Color] = [
            Color(red: 0.23, green: 0.48, blue: 0.84),
            Color(red: 1.0,  green: 0.58, blue: 0.0),
            Color(red: 0.20, green: 0.78, blue: 0.35),
            Color(red: 0.69, green: 0.32, blue: 0.87)
        ]
        return colors[abs(child.name.hashValue) % colors.count]
    }

    private var initials: String {
        let parts = child.name.split(separator: " ").prefix(2)
        let result = parts.compactMap { $0.first.map { String($0).uppercased() } }.joined()
        return result.isEmpty ? "?" : result
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
        if child.batteryLevel < 20 { return .red }
        if child.batteryLevel < 60 { return .orange }
        return .green
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        let minutes = seconds / 60
        let hours   = minutes / 60
        if seconds < 60 { return "agora" }
        if minutes < 60 { return "\(minutes)min" }
        if hours < 24   { return "\(hours)h" }
        let fmt = DateFormatter()
        fmt.dateFormat = "dd/MM"
        return fmt.string(from: date)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            HStack(spacing: 12) {
                // Avatar circle with initials
                ZStack {
                    Circle().fill(avatarColor)
                    Text(initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(child.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        StatusBadge(child: child)
                    }
                    HStack(spacing: 8) {
                        if let timestamp = child.locationTimestamp {
                            Text("há \(timeAgo(from: timestamp))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if child.lastUpdateMinutes > 0 {
                            Text("há \(child.lastUpdateMinutes)min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if child.hasAcceptedInvite {
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
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.systemGray3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemFill), lineWidth: 1)
                    )
            )
        }
    }
}
