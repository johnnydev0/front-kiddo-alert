//
//  ChildDetailView.swift
//  alert
//
//  Detail view with map for a child (Responsável mode)
//  Phase 2: Real location display
//

import SwiftUI
import MapKit

struct ChildDetailView: View {
    let childId: UUID
    @EnvironmentObject var appState: AppState
    @State private var region: MKCoordinateRegion

    // Computed property to get the latest child data from AppState
    private var child: Child? {
        appState.children.first(where: { $0.id == childId })
    }

    init(child: Child) {
        self.childId = child.id
        // Initialize region with child's last known location or default
        let center = child.lastKnownLocation ?? CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Group {
            if let child = child {
                detailContent(for: child)
            } else {
                Text("Criança não encontrada")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Localização")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailContent(for child: Child) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Child Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(child.name)
                                .font(.title2.bold())

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(statusColor(for: child))
                                    .frame(width: 8, height: 8)

                                Text(child.status.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "battery.100")
                                    .foregroundColor(.green)
                                Text("\(child.batteryLevel)%")
                            }
                            .font(.caption)

                            Text("há \(child.lastUpdateMinutes) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !child.isSharing {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)
                            Text("Compartilhamento pausado")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)

                // Map View
                VStack(alignment: .leading, spacing: 8) {
                    Text("Última Localização")
                        .font(.headline)
                        .padding(.horizontal)

                    if let location = child.lastKnownLocation {
                        ZStack(alignment: .topTrailing) {
                            Map(coordinateRegion: $region, annotationItems: [MapPin(coordinate: location)]) { pin in
                                MapMarker(coordinate: pin.coordinate, tint: .blue)
                            }
                            .frame(height: 300)
                            .cornerRadius(16)

                            // Update timestamp overlay
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Última atualização:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                if let timestamp = child.locationTimestamp {
                                    Text(timeAgo(from: timestamp))
                                        .font(.caption.bold())
                                        .foregroundColor(.primary)
                                } else {
                                    Text("há \(child.lastUpdateMinutes) min")
                                        .font(.caption.bold())
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground).opacity(0.9))
                            )
                            .padding(12)
                        }
                        .padding(.horizontal)
                    } else {
                        // No location available
                        VStack(spacing: 12) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("Localização não disponível")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Aguardando primeira atualização...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                    }
                }

                // Action Button
                Button(action: requestLocationUpdate) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Atualizar Agora")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(!child.isSharing)

                // Note
                Text("A localização é atualizada automaticamente a cada 5 minutos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .onChange(of: child.locationTimestamp) { _, _ in
                if let location = child.lastKnownLocation {
                    withAnimation {
                        region.center = location
                    }
                }
            }
        }
    }

    private func statusColor(for child: Child) -> Color {
        switch child.status {
        case .emCasa: return .green
        case .naEscola: return .blue
        case .compartilhamentoPausado: return .gray
        case .emTransito: return .orange
        }
    }

    private func requestLocationUpdate() {
        appState.locationManager.requestCurrentLocation()
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "agora"
        } else if minutes == 1 {
            return "há 1 min"
        } else if minutes < 60 {
            return "há \(minutes) min"
        } else {
            let hours = minutes / 60
            return hours == 1 ? "há 1 hora" : "há \(hours) horas"
        }
    }
}

// Helper struct for map pin
struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    NavigationStack {
        ChildDetailView(child: Child(
            name: "João",
            status: .naEscola,
            lastUpdateMinutes: 3,
            batteryLevel: 87,
            isSharing: true
        ))
    }
}
