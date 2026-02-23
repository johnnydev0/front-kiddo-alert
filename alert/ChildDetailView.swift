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

    private var child: Child? {
        appState.children.first(where: { $0.id == childId })
    }

    init(child: Child) {
        self.childId = child.id
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
                Text("Criança não encontrada").foregroundColor(.secondary)
            }
        }
        .navigationTitle(child?.name ?? "Localização")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if let child = child { editedName = child.name; showEditSheet = true }
                    } label: {
                        Label("Editar Nome", systemImage: "pencil")
                    }
                    if let child = child, !child.hasAcceptedInvite {
                        Button { generateNewInviteCode() } label: {
                            Label("Novo Código de Convite", systemImage: "ticket")
                        }
                    }
                    Divider()
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Remover Criança", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) { editChildSheet }
        .sheet(isPresented: $showInviteCodeSheet) { inviteCodeSheet }
        .alert("Remover Criança", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Remover", role: .destructive) {
                if let child = child { appState.removeChild(child); dismiss() }
            }
        } message: {
            if let child = child {
                Text("Tem certeza que deseja remover \(child.name)? Esta ação não pode ser desfeita.")
            }
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private func detailContent(for child: Child) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Map at top
                mapView(for: child)
                    .frame(height: 220)
                    .clipped()

                // Info card overlapping map
                infoCard(for: child)
                    .padding(.horizontal, 16)
                    .offset(y: -20)

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: requestLocationUpdate) {
                        HStack(spacing: 8) {
                            if isRequestingLocation {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isRequestingLocation ? "Atualizando..." : "Atualizar Agora")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue))
                    }
                    .disabled(!child.isSharing || isRequestingLocation)
                    .padding(.horizontal, 16)

                    Text("A localização é atualizada automaticamente a cada 3 minutos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.top, -4)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
        .onAppear { loadChildDetails() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                await appState.refreshChildren()
            }
        }
        .onChange(of: child.locationTimestamp) { _, _ in
            if let location = child.lastKnownLocation {
                withAnimation { region.center = location }
            }
        }
    }

    // MARK: - Map

    @ViewBuilder
    private func mapView(for child: Child) -> some View {
        if let location = child.lastKnownLocation {
            Map(coordinateRegion: $region, annotationItems: [MapPin(coordinate: location)]) { pin in
                MapMarker(coordinate: pin.coordinate, tint: .blue)
            }
        } else {
            ZStack {
                Color(.systemGray5)
                VStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Aguardando localização...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Info Card

    private func infoCard(for child: Child) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle().fill(avatarColor(for: child.name))
                    Text(initials(for: child.name))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)

                // Name + status
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(child.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        StatusBadge(child: child)
                    }
                    HStack(spacing: 10) {
                        if let timestamp = child.locationTimestamp {
                            Text("há \(timeAgo(from: timestamp))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if child.lastUpdateMinutes > 0 {
                            Text("há \(child.lastUpdateMinutes)min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 2) {
                            Image(systemName: batteryIcon(level: child.batteryLevel))
                                .font(.caption)
                                .foregroundColor(batteryColor(level: child.batteryLevel))
                            Text("\(child.batteryLevel)%")
                                .font(.caption)
                                .foregroundColor(batteryColor(level: child.batteryLevel))
                        }
                    }
                }
            }

            // Last update row
            if let timestamp = child.locationTimestamp {
                HStack(spacing: 4) {
                    Text("Última atualização:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(timestamp))
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.systemFill), lineWidth: 1)
                )
        )
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
                    Button("Cancelar") { showEditSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { saveChildName() }
                        .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveChildName() {
        guard let child = child else { return }
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task { await appState.updateChildName(child: child, newName: trimmed); showEditSheet = false }
    }

    // MARK: - Invite Code Sheet

    @ViewBuilder
    private var inviteCodeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isGeneratingCode {
                    ProgressView("Gerando código...").padding()
                } else if let code = newInviteCode {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50)).foregroundColor(.green)
                        Text("Novo Código Gerado").font(.title2.bold())
                        Text(code)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .tracking(6).foregroundColor(.primary).padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        Text("Este código expira em 7 dias").font(.caption).foregroundColor(.secondary)
                        Button {
                            UIPasteboard.general.string = code
                        } label: {
                            HStack { Image(systemName: "doc.on.doc"); Text("Copiar Código") }
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.blue).foregroundColor(.white).cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50)).foregroundColor(.orange)
                        Text("Erro ao gerar código").font(.title2.bold())
                        Text("Tente novamente mais tarde").font(.subheadline).foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Código de Convite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { showInviteCodeSheet = false; newInviteCode = nil }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func generateNewInviteCode() {
        guard let child = child else { return }
        isGeneratingCode = true; newInviteCode = nil; showInviteCodeSheet = true
        Task {
            do { newInviteCode = try await appState.generateInviteCode(for: child) }
            catch { print("❌ Erro ao gerar código: \(error)") }
            isGeneratingCode = false
        }
    }

    // MARK: - Helpers

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(red: 0.23, green: 0.48, blue: 0.84),
            Color(red: 1.0,  green: 0.58, blue: 0.0),
            Color(red: 0.20, green: 0.78, blue: 0.35),
            Color(red: 0.69, green: 0.32, blue: 0.87)
        ]
        return colors[abs(name.hashValue) % colors.count]
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let result = parts.compactMap { $0.first.map { String($0).uppercased() } }.joined()
        return result.isEmpty ? "?" : result
    }

    private func batteryIcon(level: Int) -> String {
        switch level {
        case 0..<10:  return "battery.0percent"
        case 10..<25: return "battery.25percent"
        case 25..<50: return "battery.50percent"
        case 50..<75: return "battery.75percent"
        default:      return "battery.100percent"
        }
    }

    private func batteryColor(level: Int) -> Color {
        if level < 20 { return .red }
        if level < 60 { return .orange }
        return .green
    }

    private func timeAgo(from date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        let hours = minutes / 60
        if minutes < 1 { return "agora" }
        if minutes < 60 { return "\(minutes)min" }
        if hours < 24 { return "\(hours)h" }
        let fmt = DateFormatter(); fmt.dateFormat = "dd/MM"
        return fmt.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
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
            do { try await APIService.shared.requestChildLocation(childId: childId.uuidString.lowercased()) }
            catch { print("Failed to request location: \(error)") }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await appState.refreshChildren()
            isRequestingLocation = false
        }
    }
}

// MARK: - MapPin helper
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
