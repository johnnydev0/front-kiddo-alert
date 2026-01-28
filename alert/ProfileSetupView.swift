//
//  ProfileSetupView.swift
//  alert
//
//  Profile setup screen for collecting guardian name and email
//  Shown after mode selection for new guardian users
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    enum Field {
        case name, email
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (email.isEmpty || isValidEmail(email))
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(Color.blue.gradient)

                Text("Complete seu perfil")
                    .font(.title.bold())

                Text("Seu nome aparecerá para as crianças que você monitora")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seu nome")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)

                    TextField("Como você quer ser chamado(a)?", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)

                        Text("(opcional)")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    TextField("seu@email.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)

                    Text("Usado para recuperar sua conta")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Continue button
            Button(action: saveProfile) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Continuar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(isFormValid ? Color.blue : Color.gray)
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .disabled(!isFormValid || isLoading)

            // Skip email note
            if !email.isEmpty && !isValidEmail(email) {
                Text("Por favor, insira um email válido ou deixe em branco")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .onAppear {
            focusedField = .name
        }
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await appState.completeProfileSetup(
                    name: trimmedName,
                    email: trimmedEmail.isEmpty ? "" : trimmedEmail
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AppState())
}
