import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState

    var groupedEvents: [(String, [HistoryEvent])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var grouped: [String: [HistoryEvent]] = [:]
        for event in appState.historyEvents {
            let eventDay = calendar.startOfDay(for: event.timestamp)
            let key = calendar.isDate(eventDay, inSameDayAs: today) ? "Hoje" : "Ontem"
            grouped[key, default: []].append(event)
        }
        let sorted = grouped.map { ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp }) }
        return sorted.sorted { $0.0 == "Hoje" && $1.0 != "Hoje" }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if groupedEvents.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedEvents, id: \.0) { label, events in
                        eventGroup(label: label, events: events)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Histórico")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                Image(systemName: "clock")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
            }
            Text("Nenhum evento ainda")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            Text("Os eventos aparecerão aqui quando suas crianças chegarem ou saírem dos locais monitorados")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Event Group

    private func eventGroup(label: String, events: [HistoryEvent]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(events.indices, id: \.self) { i in
                    HistoryEventRow(event: events[i], isLast: i == events.count - 1)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemFill), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - HistoryEventRow
struct HistoryEventRow: View {
    let event: HistoryEvent
    let isLast: Bool

    private var dotColor: Color { event.type.color }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline column
            VStack(spacing: 0) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)
                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            // Content
            HStack(alignment: .top) {
                Text(event.description)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)

                Text(event.timeString)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, isLast ? 12 : 0)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environmentObject(AppState())
    }
}
