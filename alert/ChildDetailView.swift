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
    @Environment(\.dismiss) var dismiss
    @State private var region: MKCoordinateRegion
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showInviteCodeSheet = false
    @State private var editedName = ""
    @State private var newInviteCode: String?
    @State private var isGeneratingCode = false
    @State private var guardians: [APIChildDetailGuardian] = []
    @State private var isRequestingLocation = false

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if let child = child {
                            editedName = child.name
                            showEditSheet = true
                        }
                    } label: {
                        Label("Editar Nome", systemImage: "pencil")
                    }

                    if let child = child, !child.hasAcceptedInvite {
                        Button {
                            generateNewInviteCode()
                        } label: {
                            Label("Novo Código de Convite", systemImage: "ticket")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Remover Criança", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            editChildSheet
        }
        .sheet(isPresented: $showInviteCodeSheet) {
            inviteCodeSheet
        }
        .alert("Remover Criança", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Remover", role: .destructive) {
                if let child = child {
                    appState.removeChild(child)
                    dismiss()
                }
            }
        } message: {
            if let child = child {
                Text("Tem certeza que deseja remover \(child.name)? Esta ação não pode ser desfeita e todos os alertas associados serão removidos.")
            }
        }
    }

    // MARK: - Edit Sheet

    @ViewBuilder
    private var editChildSheet: some View {
        NavigationStack {
            Form {
                Section("Nome da Criança") {
                    TextField("Nome", text: $editedName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Editar Criança")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showEditSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        saveChildName()
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveChildName() {
        guard let child = child else { return }
        let trimmedName = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        Task {
            await appState.updateChildName(child: child, newName: trimmedName)
            showEditSheet = false
        }
    }

    // MARK: - Invite Code Sheet

    @ViewBuilder
    private var inviteCodeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isGeneratingCode {
                    ProgressView("Gerando código...")
                        .padding()
                } else if let code = newInviteCode {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("Novo Código Gerado")
                            .font(.title2.bold())

                        Text(code)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .tracking(6)
                            .foregroundColor(.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )

                        Text("Este código expira em 7 dias")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            UIPasteboard.general.string = code
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copiar Código")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)

                        Text("Erro ao gerar código")
                            .font(.title2.bold())

                        Text("Tente novamente mais tarde")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Código de Convite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") {
                        showInviteCodeSheet = false
                        newInviteCode = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func generateNewInviteCode() {
        guard let child = child else { return }

        isGeneratingCode = true
        newInviteCode = nil
        showInviteCodeSheet = true

        Task {
            do {
                newInviteCode = try await appState.generateInviteCode(for: child)
            } catch {
                print("❌ Erro ao gerar código: \(error)")
            }
            isGeneratingCode = false
        }
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

                // Guardians section
                if !guardians.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Responsaveis")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(guardians, id: \.id) { guardian in
                                HStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(guardian.guardianUser.name ?? "Responsavel")
                                            .font(.subheadline.weight(.medium))
                                        if let email = guardian.guardianUser.email {
                                            Text(email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.tertiarySystemBackground))
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Action Button
                Button(action: requestLocationUpdate) {
                    HStack {
                        if isRequestingLocation {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRequestingLocation ? "Atualizando..." : "Atualizar Agora")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(!child.isSharing || isRequestingLocation)

                // Note
                Text("A localizacao e atualizada automaticamente a cada 5 minutos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .onAppear {
                loadChildDetails()
            }
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

    private func loadChildDetails() {
        Task {
            do {
                let detail = try await APIService.shared.getChild(id: childId.uuidString.lowercased())
                guardians = detail.guardians ?? []
            } catch {
                print("❌ Erro ao carregar detalhes: \(error)")
            }
        }
    }

    private func requestLocationUpdate() {
        Task {
            isRequestingLocation = true

            // Send FCM/APNs push to child device requesting immediate location
            do {
                try await APIService.shared.requestChildLocation(childId: childId.uuidString.lowercased())
            } catch {
                print("Failed to request location: \(error)")
            }

            // Wait for child device to receive push, get GPS, and send to backend
            try? await Task.sleep(nanoseconds: 2_500_000_000)

            // Refresh children data from backend
            await appState.refreshChildren()

            isRequestingLocation = false
        }
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
