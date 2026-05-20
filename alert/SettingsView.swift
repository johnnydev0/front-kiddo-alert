//
//  SettingsView.swift
//  alert
//
//  Configurações do usuário: perfil, responsáveis e conta
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditNameSheet = false
    @State private var editingName = ""
    @State private var isSavingName = false
    @State private var nameError: String?
    @State private var showLogoutConfirmation = false

    private var currentUser: APIUser? { appState.authManager.currentUser }

    var body: some View {
        List {
            // MARK: - Perfil
            Section("Meu Perfil") {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Text(initials)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(currentUser?.name ?? "Sem nome")
                            .font(.headline)
                        if let email = currentUser?.email, !email.isEmpty {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        editingName = currentUser?.name ?? ""
                        showEditNameSheet = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
            }

            // MARK: - Responsáveis
            Section("Responsáveis") {
                NavigationLink(value: "invite") {
                    Label("Convidar Responsável", systemImage: "person.badge.plus")
                }
                NavigationLink(value: "acceptGuardianInvite") {
                    Label("Aceitar código de convite", systemImage: "ticket")
                }
            }

            // MARK: - Segurança
            if currentUser?.email != nil {
                Section("Segurança") {
                    NavigationLink(value: "changePassword") {
                        Label("Alterar Senha", systemImage: "lock.rotation")
                    }
                }
            }

            // MARK: - Conta
            Section("Conta") {
                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    Label("Trocar Perfil", systemImage: "arrow.left.arrow.right")
                }
            }
        }
        .navigationTitle("Configurações")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditNameSheet) {
            editNameSheet
        }
        .alert("Trocar Perfil", isPresented: $showLogoutConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Trocar", role: .destructive) {
                Task { await appState.logout() }
            }
        } message: {
            Text("Você será desconectado e poderá escolher um novo perfil (Responsável ou Criança).")
        }
    }

    // MARK: - Iniciais do avatar

    private var initials: String {
        guard let name = currentUser?.name, !name.isEmpty else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Sheet de edição de nome

    @ViewBuilder
    private var editNameSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome", text: $editingName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                if let error = nameError {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Editar Nome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showEditNameSheet = false
                        nameError = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSavingName {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Button("Salvar") { saveName() }
                            .disabled(editingName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func saveName() {
        let name = editingName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isSavingName = true
        nameError = nil
        Task {
            do {
                try await appState.authManager.updateUserName(name)
                showEditNameSheet = false
            } catch {
                nameError = error.localizedDescription
            }
            isSavingName = false
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
}
