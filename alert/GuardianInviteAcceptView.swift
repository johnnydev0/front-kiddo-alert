//
//  GuardianInviteAcceptView.swift
//  alert
//
//  Screen for a second guardian to enter an invite code
//  and accept access to a child's location
//

import SwiftUI

struct GuardianInviteAcceptView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var inviteDetails: InviteDetailsResponse?
    @State private var isAccepted = false
    @FocusState private var isCodeFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isAccepted {
                    successView
                } else if let details = inviteDetails {
                    confirmView(details: details)
                } else {
                    codeInputView
                }
            }
            .padding()
        }
        .navigationTitle("Aceitar Convite")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Code Input

    @ViewBuilder
    private var codeInputView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "ticket.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                }

                Text("Codigo de Convite")
                    .font(.title2.bold())

                Text("Digite o codigo de 6 caracteres que voce recebeu de outro responsavel")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            // Code input
            TextField("ABC123", text: $inviteCode)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .focused($isCodeFieldFocused)
                .onChange(of: inviteCode) { _, newValue in
                    let filtered = String(newValue.uppercased().prefix(6))
                    if filtered != newValue {
                        inviteCode = filtered
                    }
                }

            Text("O codigo tem 6 letras e numeros")
                .font(.caption)
                .foregroundColor(.secondary)

            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
            }

            Button(action: verifyCode) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Verificar Codigo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(inviteCode.count == 6 ? Color.green : Color.gray)
            .cornerRadius(12)
            .disabled(inviteCode.count != 6 || isLoading)
        }
        .onAppear {
            isCodeFieldFocused = true
        }
    }

    // MARK: - Confirm View

    @ViewBuilder
    private func confirmView(details: InviteDetailsResponse) -> some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }

                Text("Confirmar Convite")
                    .font(.title2.bold())
            }
            .padding(.top, 20)

            // Invite details card
            VStack(spacing: 16) {
                if let createdBy = details.createdByName {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("Convidado por")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(createdBy)
                                .font(.body.weight(.medium))
                        }
                        Spacer()
                    }
                }

                if let childName = details.childName {
                    HStack {
                        Image(systemName: "figure.child")
                            .foregroundColor(.green)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("Crianca")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(childName)
                                .font(.body.weight(.medium))
                        }
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )

            Text("Ao aceitar, voce podera acompanhar a localizacao desta crianca e receber alertas.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
            }

            // Action buttons
            VStack(spacing: 12) {
                Button(action: acceptInvite) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Aceitar Convite")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.green)
                .cornerRadius(12)
                .disabled(isLoading)

                Button {
                    inviteDetails = nil
                    inviteCode = ""
                    errorMessage = nil
                } label: {
                    Text("Voltar")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Success View

    @ViewBuilder
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Convite Aceito!")
                    .font(.title.bold())

                Text("Voce agora pode acompanhar a localizacao da crianca.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                dismiss()
            } label: {
                Text("Voltar ao Inicio")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func verifyCode() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let details = try await APIService.shared.getInviteDetails(token: inviteCode)

                guard details.invite.type == "add_guardian" else {
                    errorMessage = "Este codigo nao e um convite de responsavel"
                    isLoading = false
                    return
                }

                inviteDetails = details
            } catch let error as APIError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func acceptInvite() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await appState.acceptGuardianInvite(code: inviteCode)
                withAnimation {
                    isAccepted = true
                }
            } catch let error as APIError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        GuardianInviteAcceptView()
            .environmentObject(AppState())
    }
}
