import Combine
import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var draft: String = ""
    @Published var isThinking = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var carrotCount = 0
    @Published var showCarrotBurst = false

    let classItem: ClassItem

    private let messagesRepo: any MessageRepository
    private let materialsRepo: any MaterialRepository
    private let service: ClaudeService
    private var burstTask: Task<Void, Never>?

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking && !isLoading
    }

    var bunnyState: BunnyState {
        if isLoading || isThinking { return .thinking }
        if showCarrotBurst { return .happy }
        return .idle
    }

    init(
        classItem: ClassItem,
        messagesRepo: any MessageRepository,
        materialsRepo: any MaterialRepository,
        service: ClaudeService = ClaudeService(),
        previewMessages: [Message]? = nil,
        previewCarrots: Int? = nil
    ) {
        self.classItem = classItem
        self.messagesRepo = messagesRepo
        self.materialsRepo = materialsRepo
        self.service = service
        if let previewMessages {
            self.messages = previewMessages
            self.carrotCount = previewCarrots ?? (previewMessages.filter(\.isFromStudent).count / 3)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await messagesRepo.fetchMessages(classId: classItem.id)
            withAnimation(HoppersTheme.softSpring) {
                messages = loaded
                if messages.isEmpty {
                    messages = [Message.greeting(for: classItem)]
                }
            }
            carrotCount = studentMessageCount / 3
            errorMessage = nil
        } catch {
            errorMessage = AppError.from(error).bunnyMessage
            if messages.isEmpty {
                messages = [Message.greeting(for: classItem)]
            }
        }
    }

    func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }

        draft = ""
        let userMessage = Message(classId: classItem.id, role: .user, content: text)
        withAnimation(HoppersTheme.spring) {
            messages.append(userMessage)
        }
        refreshCarrots()
        Task {
            _ = try? await messagesRepo.insertMessage(
                classId: classItem.id,
                role: .user,
                content: text
            )
        }

        isThinking = true
        Task {
            defer {
                withAnimation(HoppersTheme.softSpring) {
                    isThinking = false
                }
            }
            do {
                let materials = try await materialsRepo.fetchMaterials(classId: classItem.id)
                var imageBytes: [UUID: Data] = [:]
                for material in materials where material.type == .image {
                    if let data = try? await materialsRepo.downloadData(for: material) {
                        imageBytes[material.id] = data
                    }
                }
                let reply = try await service.complete(
                    classItem: classItem,
                    history: messages,
                    materials: materials,
                    imageBytes: imageBytes
                )
                let assistant = Message(classId: classItem.id, role: .assistant, content: reply)
                withAnimation(HoppersTheme.spring) {
                    messages.append(assistant)
                }
                Task {
                    _ = try? await messagesRepo.insertMessage(
                        classId: classItem.id,
                        role: .assistant,
                        content: reply
                    )
                }
            } catch let error as ClaudeError {
                withAnimation(HoppersTheme.spring) {
                    messages.append(
                        Message(
                            classId: classItem.id,
                            role: .assistant,
                            content: error.bunnyMessage,
                            isError: true
                        )
                    )
                }
            } catch {
                withAnimation(HoppersTheme.spring) {
                    messages.append(
                        Message(
                            classId: classItem.id,
                            role: .assistant,
                            content: AppError.from(error).bunnyMessage,
                            isError: true
                        )
                    )
                }
            }
        }
    }

    func clearChat() async {
        let previous = messages
        withAnimation {
            messages = [Message.greeting(for: classItem)]
            carrotCount = 0
        }
        do {
            try await messagesRepo.clearMessages(classId: classItem.id)
        } catch {
            messages = previous
            errorMessage = AppError.from(error).bunnyMessage
        }
    }

    private var studentMessageCount: Int {
        messages.filter(\.isFromStudent).count
    }

    private func refreshCarrots() {
        let newCount = studentMessageCount / 3
        if newCount > carrotCount {
            carrotCount = newCount
            showCarrotBurst = true
            burstTask?.cancel()
            burstTask = Task {
                try? await Task.sleep(for: .milliseconds(1600))
                guard !Task.isCancelled else { return }
                withAnimation(HoppersTheme.softSpring) {
                    showCarrotBurst = false
                }
            }
        } else {
            carrotCount = newCount
        }
    }
}

extension ChatViewModel {
    static var preview: ChatViewModel {
        ChatViewModel(
            classItem: HoppersPreviewData.history,
            messagesRepo: MockMessageRepository(),
            materialsRepo: MockMaterialRepository(),
            previewMessages: [
                Message.greeting(for: HoppersPreviewData.history),
                Message(
                    classId: HoppersPreviewData.history.id,
                    role: .user,
                    content: "Why is the sky blue?"
                ),
                Message(
                    classId: HoppersPreviewData.history.id,
                    role: .assistant,
                    content: "Great question! Sunlight is made of every color. Air molecules scatter the short blue wavelengths more than the rest, so blue light bounces into our eyes from every direction."
                )
            ],
            previewCarrots: 1
        )
    }
}
