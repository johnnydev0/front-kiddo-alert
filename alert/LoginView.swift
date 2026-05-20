import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    let onBack: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPasswordSheet = false
    @State private var forgotEmail = ""
    @State private var isSendingForgot = false
    @State private var forgotSuccess = false
    @State private var forgotError: String?
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    KidoLogoView(size: 56)
                    Text("Entrar na sua conta")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Use o email e a senha enviada para você")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                // Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        TextField("seu@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Senha")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        SecureField("Sua senha", text: $password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { performLogin() }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: performLogin) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("Entrar")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(isLoading || email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)

                    Button("Esqueceu sua senha?") {
                        forgotEmail = email
                        forgotSuccess = false
                        forgotError = nil
                        showForgotPasswordSheet = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Voltar", action: onBack)
            }
        }
        .sheet(isPresented: $showForgotPasswordSheet) {
            forgotPasswordSheet
        }
    }

    // MARK: - Forgot Password Sheet

    private var forgotPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.blue)
                    Text("Recuperar senha")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Vamos enviar uma nova senha para o seu email.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 16)

                if forgotSuccess {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("Se esse email estiver cadastrado, você receberá sua nova senha em breve.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    VStack(spacing: 12) {
                        TextField("seu@email.com", text: $forgotEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .padding(.horizontal, 24)

                        if let error = forgotError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button(action: performForgotPassword) {
                            if isSendingForgot {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                Text("Enviar nova senha")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 24)
                        .disabled(isSendingForgot || forgotEmail.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Spacer()
            }
            .navigationTitle("Recuperar senha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { showForgotPasswordSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func performLogin() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !password.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        focusedField = nil

        Task {
            do {
                try await appState.authManager.login(email: trimmedEmail, password: password)
                // On success AuthManager updates state and ContentView navigates automatically
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func performForgotPassword() {
        let trimmedEmail = forgotEmail.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else { return }

        isSendingForgot = true
        forgotError = nil

        Task {
            do {
                try await appState.authManager.forgotPassword(email: trimmedEmail)
                forgotSuccess = true
            } catch {
                forgotError = error.localizedDescription
            }
            isSendingForgot = false
        }
    }
}
