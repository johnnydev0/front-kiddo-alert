//
//  InviteView.swift
//  alert
//
//  Screen to generate and share guardian invite codes
//

import SwiftUI

struct InviteView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedChild: Child?
    @State private var inviteCode: String?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showCopiedMessage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                    }

                    Text("Convidar Responsavel")
                        .font(.title2.bold())

                    Text("Gere um codigo para outro responsavel acompanhar a localizacao das criancas")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)

                // Explanation
                VStack(alignment: .leading, spacing: 16) {
                    ExplanationRow(
                        icon: "ticket",
                        title: "Gere um codigo",
                        description: "Compartilhe com outro responsavel"
                    )

                    ExplanationRow(
                        icon: "shield.checkmark",
                        title: "Seguro e privado",
                        description: "Apenas quem tem o codigo pode se conectar"
                    )

                    ExplanationRow(
                        icon: "bell.fill",
                        title: "Alertas compartilhados",
                        description: "Todos recebem notificacoes das criancas"
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )

                // Limits info
                if let limits = appState.authManager.userLimits {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Responsaveis adicionais")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(limits.current.guardians) de \(limits.limits.maxGuardians)")
                                .font(.subheadline.weight(.semibold))
                        }
                        ProgressView(value: Double(limits.current.guardians), total: Double(limits.limits.maxGuardians))
                            .tint(.green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }

                // Child selection
                if appState.children.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selecione a crianca")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)

                        ForEach(appState.children) { child in
                            Button {
                                selectedChild = child
                                inviteCode = nil
                                errorMessage = nil
                            } label: {
                                HStack {
                                    Image(systemName: selectedChild?.id == child.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedChild?.id == child.id ? .green : .gray)

                                    Text(child.name)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedChild?.id == child.id ? Color.green.opacity(0.1) : Color(.tertiarySystemBackground))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Generated code display
                if let code = inviteCode {
                    VStack(spacing: 16) {
                        Text("Codigo de Convite")
                            .font(.headline)

                        if let child = selectedChild {
                            Text("para \(child.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text(code)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )

                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = code
                                withAnimation { showCopiedMessage = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { showCopiedMessage = false }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: showCopiedMessage ? "checkmark" : "doc.on.doc")
                                    Text(showCopiedMessage ? "Copiado!" : "Copiar")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button {
                                shareCode(code)
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Enviar")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }

                        Text("Este codigo expira em 7 dias")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                } else {
                    // Generate button
                    Button(action: generateCode) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "ticket.fill")
                            }
                            Text("Gerar Codigo de Convite")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canGenerate ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canGenerate || isGenerating)
                }

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

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Convite")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Auto-select if only one child
            if appState.children.count == 1 {
                selectedChild = appState.children.first
            }
        }
    }

    private var canGenerate: Bool {
        selectedChild != nil && !isGenerating
    }

    private func generateCode() {
        guard let child = selectedChild else { return }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                inviteCode = try await appState.generateGuardianInviteCode(for: child)
            } catch let error as APIError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }

    private func shareCode(_ code: String) {
        let childName = selectedChild?.name ?? "crianca"
        let message = """
        Ola! Baixe o app KidoAlert e use o codigo \(code) para acompanhar a localizacao de \(childName).

        1. Baixe o KidoAlert
        2. Selecione "Sou Responsavel"
        3. Toque em "Tenho um codigo de convite"
        4. Digite o codigo: \(code)
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

// MARK: - Explanation Row Component
struct ExplanationRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)

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

#Preview {
    NavigationStack {
        InviteView()
            .environmentObject(AppState())
    }
}
