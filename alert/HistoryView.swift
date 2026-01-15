//
//  HistoryView.swift
//  alert
//
//  Timeline of arrival/departure events
//

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

        // Sort groups and events
        let sortedGroups = grouped.map { ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp }) }
        return sortedGroups.sorted { $0.0 == "Hoje" && $1.0 != "Hoje" }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Histórico")
                        .font(.title.bold())

                    Text("Eventos de chegada e saída")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)

                // Timeline
                ForEach(groupedEvents, id: \.0) { section in
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        Text(section.0)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)

                        // Events
                        ForEach(section.1) { event in
                            EventRow(event: event)
                        }
                    }
                }

                if groupedEvents.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)

                        Text("Nenhum evento ainda")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Os eventos de chegada e saída aparecerão aqui")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Histórico")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Event Row Component
struct EventRow: View {
    let event: HistoryEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline dot and line
            VStack(spacing: 0) {
                Circle()
                    .fill(event.type.color)
                    .frame(width: 12, height: 12)

                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 2, height: 40)
            }

            // Event content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: event.type.icon)
                        .foregroundColor(event.type.color)

                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.primary)
                }

                Text(event.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environmentObject(AppState())
    }
}
