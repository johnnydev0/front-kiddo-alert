//
//  AddChildView.swift
//  alert
//
//  Screen to add a new child to the family
//  Integrates with backend API to create child and generate invite code
//

import SwiftUI

struct AddChildView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var childName = ""
    @State private var showPaywall = false
    @State private var inviteCode: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCopiedMessage = false

    var currentChildrenCount: Int {
        appState.children.count
    }

    var maxChildren: Int {
        appState.authManager.currentLimits?.maxChildren ?? 2
    }

    var isAtLimit: Bool {
        currentChildrenCount >= maxChildren
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header Icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }

                    VStack(spacing: 8) {
                        Text("Adicionar Crianca")
                            .font(.title2.bold())
                            .foregroundColor(.primary)

                        Text("Convide a crianca para conectar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Counter with Premium CTA
                VStack(spacing: 12) {
                    HStack {
                        Text("\(currentChildrenCount) de \(maxChildren) criancas")
                            .font(.subheadline)
                            .foregroundColor(isAtLimit ? .orange : .secondary)

                        Spacer()

                        if isAtLimit {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    if isAtLimit {
                        Button(action: { showPaywall = true }) {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Upgrade para Premium")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )

                // Show invite code or form
                if let code = inviteCode {
                    inviteCodeView(code: code)
                } else {
                    formView
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Adicionar Crianca")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Form View

    var formView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Explanation steps
            VStack(alignment: .leading, spacing: 20) {
                Text("Como Funciona")
                    .font(.headline)

                StepRow(
                    number: 1,
                    title: "Digite o nome da crianca",
                    description: "Para identificar no app"
                )

                StepRow(
                    number: 2,
                    title: "Gere um codigo de convite",
                    description: "Codigo de 6 digitos"
                )

                StepRow(
                    number: 3,
                    title: "A crianca digita o codigo",
                    description: "No app dela, e o compartilhamento comeca"
                )
            }

            Divider()

            // Form
            VStack(alignment: .leading, spacing: 16) {
                Text("Informacoes da Crianca")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nome")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Ex: Joao, Maria", text: $childName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // Generate button
                if !childName.isEmpty {
                    Button(action: generateInvite) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "ticket.fill")
                                Text("Gerar Codigo de Convite")
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isAtLimit ? Color.orange : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                }
            }

            // Info boxes
            VStack(spacing: 12) {
                InfoBox(
                    icon: "lock.shield.fill",
                    text: "A crianca sempre precisa aceitar o convite",
                    color: .blue
                )

                InfoBox(
                    icon: "hand.raised.fill",
                    text: "Ela pode pausar o compartilhamento a qualquer momento",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Invite Code View

    func inviteCodeView(code: String) -> some View {
        VStack(spacing: 24) {
            // Success header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("\(childName) adicionado!")
                    .font(.title2.bold())

                Text("Compartilhe o codigo abaixo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Big code display
            VStack(spacing: 12) {
                Text("Codigo de Convite")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(code)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .tracking(8)
                    .foregroundColor(.primary)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )

                if showCopiedMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Codigo copiado!")
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                }
            }

            // Action buttons
            VStack(spacing: 12) {
                Button(action: copyCode) {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copiar Codigo")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button(action: shareCode) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Compartilhar")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }

            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                Divider()

                Text("Instrucoes para a crianca")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    InstructionRow(number: 1, text: "Baixar o app KidoAlert")
                    InstructionRow(number: 2, text: "Selecionar \"Sou Crianca\"")
                    InstructionRow(number: 3, text: "Digitar o codigo: \(code)")
                }
            }

            // Expiration info
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption)
                Text("Este codigo expira em 7 dias")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            // Done button
            Button(action: { dismiss() }) {
                Text("Concluir")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Actions

    private func generateInvite() {
        if isAtLimit {
            showPaywall = true
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await appState.addChild(name: childName)

                if let (_, token) = result {
                    withAnimation {
                        inviteCode = token
                    }
                } else {
                    // Offline mode - generate mock code
                    withAnimation {
                        inviteCode = "DEMO01"
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    private func copyCode() {
        guard let code = inviteCode else { return }
        UIPasteboard.general.string = code

        withAnimation {
            showCopiedMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }

    private func shareCode() {
        guard let code = inviteCode else { return }

        let message = """
        Ola! Baixe o app KidoAlert e use o codigo \(code) para conectar comigo.

        1. Baixe o KidoAlert
        2. Selecione "Sou Crianca"
        3. Digite o codigo: \(code)
        """

        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Instruction Row Component
struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number).")
                .font(.subheadline.bold())
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Step Row Component
struct StepRow: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Info Box Component
struct InfoBox: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    NavigationStack {
        AddChildView()
            .environmentObject(AppState())
    }
}
