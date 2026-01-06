//
//  ChildDetailView.swift
//  alert
//
//  Detail view with map for a child (Responsável mode)
//

import SwiftUI
import MapKit

struct ChildDetailView: View {
    let child: Child
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
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
                                    .fill(statusColor)
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

                    ZStack(alignment: .topTrailing) {
                        Map(coordinateRegion: $region, annotationItems: [MapPin(coordinate: region.center)]) { pin in
                            MapMarker(coordinate: pin.coordinate, tint: .blue)
                        }
                        .frame(height: 300)
                        .cornerRadius(16)
                        .disabled(true) // Mock - no interaction

                        // Update timestamp overlay
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Última atualização:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("há \(child.lastUpdateMinutes) min")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground).opacity(0.9))
                        )
                        .padding(12)
                    }
                    .padding(.horizontal)
                }

                // Action Button
                Button(action: {}) {
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

                // Note
                Text("A localização é atualizada automaticamente a cada 5 minutos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Localização")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusColor: Color {
        switch child.status {
        case .emCasa: return .green
        case .naEscola: return .blue
        case .compartilhamentoPausado: return .gray
        case .emTransito: return .orange
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
