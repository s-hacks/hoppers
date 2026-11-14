import Combine
import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var services: HoppersServices
    let classItem: ClassItem

    var body: some View {
        ChatScreen(
            viewModel: ChatViewModel(
                classItem: classItem,
                messagesRepo: services.messages,
                materialsRepo: services.materials,
                service: services.claude
            )
        )
    }
}

private struct ChatScreen: View {
    @StateObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var inputFocused: Bool
    @State private var showMaterials = false
    @State private var confirmClear = false

    init(viewModel: ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var classItem: ClassItem { viewModel.classItem }
    private var classColor: Color { classItem.color }

    var body: some View {
        ZStack {
            HoppersBackground()

            VStack(spacing: 0) {
                header
                ZStack {
                    messageList
                    if viewModel.isLoading {
                        BunnyLoadingView(message: "Remembering this class…")
                    }
                }
                inputBar
            }
        }
        .font(.system(.body, design: .rounded))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showMaterials) {
            MaterialsView(classItem: classItem)
        }
        .sensoryFeedback(.success, trigger: viewModel.carrotCount)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.messages.count)
        .task { await viewModel.load() }
        .confirmationDialog("Clear this chat?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear chat", role: .destructive) {
                Task { await viewModel.clearChat() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This Hopper will forget the conversation, but materials stay.")
        }
        .alert("Oh carrots!", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(HoppersTheme.plum)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
                    .hoppersShadow(0.08)
            }
            .accessibilityLabel("Back")

            ZStack {
                Circle()
                    .fill(classColor)
                    .frame(width: 56, height: 56)
                BunnyView(state: viewModel.bunnyState, size: 52)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(classItem.botName)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(HoppersTheme.plum)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(classItem.emoji)
                    Text(classItem.name)
                }
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(HoppersTheme.plum.opacity(0.7))
            }

            Spacer()

            Button {
                showMaterials = true
            } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(HoppersTheme.plum)
                    .rotationEffect(.degrees(-25))
                    .frame(width: 40, height: 40)
                    .background(classColor.opacity(0.85))
                    .clipShape(Circle())
                    .hoppersShadow(0.08)
            }
            .accessibilityLabel("Materials")

            Menu {
                Button(role: .destructive) {
                    confirmClear = true
                } label: {
                    Label("Clear chat", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(HoppersTheme.plum)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Chat menu")

            CarrotCounter(count: viewModel.carrotCount, bursting: viewModel.showCarrotBurst)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.45))
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.messages, id: \.id) { message in
                        MessageBubble(
                            message: message,
                            accent: classColor,
                            studentAccent: HoppersTheme.lavender.opacity(0.95)
                        )
                        .id(message.id)
                    }

                    if viewModel.isThinking {
                        TypingIndicator(name: classItem.botName, accent: classColor)
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToLatest(proxy)
            }
            .onChange(of: viewModel.isThinking) { _, _ in
                scrollToLatest(proxy)
            }
            .onAppear {
                scrollToLatest(proxy)
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask \(classItem.botName) anything…", text: $viewModel.draft, axis: .vertical)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(HoppersTheme.plum)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(classColor.opacity(0.7), lineWidth: 1.5)
                )
                .onSubmit {
                    viewModel.send()
                }

            Button {
                viewModel.send()
            } label: {
                Image(systemName: viewModel.canSend ? "carrot.fill" : "paperplane.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(viewModel.canSend ? HoppersTheme.carrot : classColor)
                    .clipShape(Circle())
                    .shadow(
                        color: (viewModel.canSend ? HoppersTheme.carrot : classColor).opacity(0.4),
                        radius: 8,
                        y: 4
                    )
                    .rotationEffect(.degrees(viewModel.canSend ? -18 : 0))
            }
            .disabled(!viewModel.canSend)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.white.opacity(0.72))
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        withAnimation(HoppersTheme.softSpring) {
            if viewModel.isThinking {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = viewModel.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    var accent: Color = HoppersTheme.blushPink
    var studentAccent: Color = HoppersTheme.lavender

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromStudent {
                Spacer(minLength: 48)
                bubble
            } else {
                ZStack {
                    Circle()
                        .fill(accent)
                        .frame(width: 40, height: 40)
                    BunnyView(state: .idle, size: 36)
                }
                bubble
                Spacer(minLength: 36)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }

    private var bubble: some View {
        Text(message.text)
            .font(.system(.body, design: .rounded))
            .foregroundStyle(HoppersTheme.plum)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(background)
            .clipShape(bubbleShape)
            .overlay(
                bubbleShape.stroke(message.isError ? HoppersTheme.carrot.opacity(0.45) : .clear, lineWidth: 1.5)
            )
            .hoppersShadow(0.08)
            .textSelection(.enabled)
    }

    private var background: Color {
        if message.isError { return HoppersTheme.babyBlue.opacity(0.85) }
        return message.isFromStudent ? studentAccent : accent
    }

    private var bubbleShape: UnevenRoundedRectangle {
        if message.isFromStudent {
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 22, bottomLeading: 22, bottomTrailing: 6, topTrailing: 22),
                style: .continuous
            )
        } else {
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 22, bottomLeading: 6, bottomTrailing: 22, topTrailing: 22),
                style: .continuous
            )
        }
    }
}

struct TypingIndicator: View {
    var name: String = "Hoppers"
    var accent: Color = HoppersTheme.blushPink
    @State private var bounce = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent)
                    .frame(width: 40, height: 40)
                BunnyView(state: .thinking, size: 36)
            }

            HStack(spacing: 8) {
                Text("\(name) is thinking")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(HoppersTheme.plum.opacity(0.8))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(HoppersTheme.plum.opacity(0.45))
                            .frame(width: 6, height: 6)
                            .offset(y: bounce ? -3 : 3)
                            .animation(
                                .easeInOut(duration: 0.42)
                                    .repeatForever()
                                    .delay(Double(index) * 0.12),
                                value: bounce
                            )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(accent.opacity(0.9))
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: .init(topLeading: 22, bottomLeading: 6, bottomTrailing: 22, topTrailing: 22),
                    style: .continuous
                )
            )

            Spacer(minLength: 36)
        }
        .onAppear { bounce = true }
        .accessibilityLabel("\(name) is thinking")
    }
}

struct CarrotCounter: View {
    let count: Int
    var bursting: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "carrot.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(HoppersTheme.carrot)
                .rotationEffect(.degrees(-20))
                .scaleEffect(bursting ? 1.25 : 1)

            Text("\(count)")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(HoppersTheme.plum)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.9))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(HoppersTheme.carrot.opacity(0.35), lineWidth: 1)
        )
        .hoppersShadow(0.08)
        .overlay(alignment: .top) {
            if bursting {
                Text("+1")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(HoppersTheme.carrot)
                    .offset(y: -16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(HoppersTheme.spring, value: bursting)
        .accessibilityLabel("Carrot counter, \(count)")
    }
}

#Preview("Chat") {
    NavigationStack {
        ChatScreen(viewModel: .preview)
    }
    .environmentObject(HoppersServices.preview)
}

#Preview("Chat empty") {
    NavigationStack {
        ChatView(classItem: HoppersPreviewData.math)
    }
    .environmentObject(HoppersServices.preview)
}
