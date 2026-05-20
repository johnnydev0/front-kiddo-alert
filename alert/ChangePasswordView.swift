import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @FocusState private var focusedField: Field?

    private enum Field { case current, new, confirm }

    private var passwordsMatch: Bool {
        newPassword == confirmPassword
    }

    private var canSubmit: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        passwordsMatch &&
        !isLoading
    }

    var body: some View {
        Form {
            Section {
                SecureField("Senha atual", text: $currentPassword)
                    .focused($focusedField, equals: .current)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .new }
            } header: {
                Text("Senha atual")
            }

            Section {
                SecureField("Nova senha (mínimo 8 caracteres)", text: $newPassword)
                    .focused($focusedField, equals: .new)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .confirm }

                SecureField("Confirmar nova senha", text: $confirmPassword)
                    .focused($focusedField, equals: .confirm)
                    .submitLabel(.done)
                    .onSubmit { if canSubmit { performChange() } }
            } header: {
                Text("Nova senha")
            } footer: {
                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("As senhas não coincidem.")
                        .foregroundColor(.red)
                } else if newPassword.count > 0 && newPassword.count < 8 {
                    Text("A senha deve ter pelo menos 8 caracteres.")
                        .foregroundColor(.red)
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Alterar Senha")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Button("Salvar", action: performChange)
                        .disabled(!canSubmit)
                }
            }
        }
        .alert("Senha alterada!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Sua senha foi atualizada com sucesso.")
        }
    }

    private func performChange() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        focusedField = nil

        Task {
            do {
                try await appState.authManager.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environmentObject(AppState())
    }
}
