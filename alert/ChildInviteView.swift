//
//  ChildInviteView.swift
//  alert
//
//  Screen for children to enter the invite code received from guardian
//

import SwiftUI

struct ChildInviteView: View {
    @EnvironmentObject var appState: AppState
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isCodeFieldFocused: Bool

    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Voltar")
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.horizontal)

            Spacer()

            // Icon and title
            VStack(spacing: 16) {
                Image(systemName: "ticket.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.green.gradient)

                Text("Digite o Código")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Peça o código de 6 dígitos para seu responsável")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Code input
            VStack(spacing: 16) {
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
                        // Limit to 6 characters and uppercase
                        let filtered = String(newValue.uppercased().prefix(6))
                        if filtered != newValue {
                            inviteCode = filtered
                        }
                    }

                Text("O código tem 6 letras e números")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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
            Button(action: submitCode) {
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
            .background(inviteCode.count == 6 ? Color.green : Color.gray)
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .disabled(inviteCode.count != 6 || isLoading)

            Spacer()
        }
        .onAppear {
            isCodeFieldFocused = true
        }
    }

    private func submitCode() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await appState.authenticateAsChildWithInvite(code: inviteCode)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    ChildInviteView(onBack: {})
        .environmentObject(AppState())
}
