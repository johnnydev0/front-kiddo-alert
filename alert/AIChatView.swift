import SwiftUI

struct AIChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false

    private let api = APIService.shared

    var body: some View {
        VStack(spacing: 0) {
            messagesView
            Divider()
            inputBar
        }
        .navigationTitle("Assistente")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Messages

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if messages.isEmpty && !isLoading {
                        emptyState
                    }

                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if isLoading {
                        LoadingBubble()
                            .id("loading")
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: isLoading) { loading in
                if loading {
                    withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Pergunte sobre o histórico")
                .font(.headline)
            Text("Ex: \"Meu filho chegou em casa hoje?\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Pergunte sobre o histórico...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(canSend ? .blue : .secondary)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    // MARK: - Actions

    private func sendMessage() {
        let question = inputText.trimmingCharacters(in: .whitespaces)
        guard !question.isEmpty else { return }

        messages.append(ChatMessage(role: "user", content: question))
        inputText = ""
        isLoading = true

        Task {
            do {
                let answer = try await api.askHistoryQuestion(question: question)
                await MainActor.run {
                    messages.append(ChatMessage(role: "assistant", content: answer))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(role: "assistant", content: "Não foi possível processar sua pergunta. Tente novamente."))
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(isUser ? .white : .primary)
                    .clipShape(
                        RoundedCornerShape(
                            radius: 18,
                            sharpCorner: isUser ? .bottomTrailing : .bottomLeading
                        )
                    )

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Loading Bubble

private struct LoadingBubble: View {
    @State private var dotCount: Int = 0

    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Text(String(repeating: ".", count: dotCount + 1))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .onReceive(timer) { _ in
                    dotCount = (dotCount + 1) % 3
                }
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Rounded Corner Shape (sharp on one corner)

private struct RoundedCornerShape: Shape {
    let radius: CGFloat
    let sharpCorner: Corner

    enum Corner { case bottomLeading, bottomTrailing }

    func path(in rect: CGRect) -> Path {
        let r = min(radius, min(rect.width, rect.height) / 2)
        let sharpR: CGFloat = 4

        let (bl, br): (CGFloat, CGFloat)
        switch sharpCorner {
        case .bottomLeading:  (bl, br) = (sharpR, r)
        case .bottomTrailing: (bl, br) = (r, sharpR)
        }

        var path = Path()
        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: 0))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}
