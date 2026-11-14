import Foundation
import Supabase

protocol MessageRepository: Sendable {
    func fetchMessages(classId: UUID) async throws -> [Message]
    func insertMessage(classId: UUID, role: Message.Role, content: String) async throws -> Message
    func clearMessages(classId: UUID) async throws
}

struct SupabaseMessageRepository: MessageRepository {
    private var client: SupabaseClient { SupabaseManager.client }

    func fetchMessages(classId: UUID) async throws -> [Message] {
        try await client
            .from("messages")
            .select()
            .eq("class_id", value: classId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func insertMessage(classId: UUID, role: Message.Role, content: String) async throws -> Message {
        let insert = MessageInsert(
            id: UUID(),
            classId: classId,
            role: role.rawValue,
            content: content
        )
        return try await client
            .from("messages")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    func clearMessages(classId: UUID) async throws {
        try await client
            .from("messages")
            .delete()
            .eq("class_id", value: classId)
            .execute()
    }
}

final class MockMessageRepository: MessageRepository, @unchecked Sendable {
    var messages: [Message] = [
        Message.greeting(for: HoppersPreviewData.history),
        Message(
            classId: HoppersPreviewData.history.id,
            role: .user,
            content: "What’s the difference between the Renaissance and the Enlightenment?"
        ),
        Message(
            classId: HoppersPreviewData.history.id,
            role: .assistant,
            content: "Nice question. The Renaissance is the “rebirth” of art and classical learning; the Enlightenment is later, more about reason, science, and questioning old authority."
        )
    ]

    func fetchMessages(classId: UUID) async throws -> [Message] {
        messages.filter { $0.classId == classId }.sorted { $0.createdAt < $1.createdAt }
    }

    func insertMessage(classId: UUID, role: Message.Role, content: String) async throws -> Message {
        let message = Message(classId: classId, role: role, content: content)
        messages.append(message)
        return message
    }

    func clearMessages(classId: UUID) async throws {
        messages.removeAll { $0.classId == classId }
    }
}
