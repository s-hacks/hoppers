import Foundation

struct Message: Identifiable, Hashable, Codable, Sendable {
    enum Role: String, Codable, Sendable {
        case user
        case assistant
    }

    let id: UUID
    var classId: UUID
    var role: Role
    var content: String
    var createdAt: Date
    var isError: Bool
    var isLocalOnly: Bool

    var text: String { content }
    var isFromStudent: Bool { role == .user }

    enum CodingKeys: String, CodingKey {
        case id
        case classId = "class_id"
        case role
        case content
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        classId: UUID,
        role: Role,
        content: String,
        createdAt: Date = Date(),
        isError: Bool = false,
        isLocalOnly: Bool = false
    ) {
        self.id = id
        self.classId = classId
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.isError = isError
        self.isLocalOnly = isLocalOnly
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        classId = try container.decode(UUID.self, forKey: .classId)
        role = try container.decode(Role.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isError = false
        isLocalOnly = false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(classId, forKey: .classId)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
    }

    static func greeting(for classItem: ClassItem) -> Message {
        Message(
            classId: classItem.id,
            role: .assistant,
            content: "Hi! I’m \(classItem.botName) \(classItem.emoji) Ready to hop into \(classItem.name)? Ask me anything — homework, a tricky concept, or “explain it like I’m tired.” Let’s nibble this down together.",
            isLocalOnly: true
        )
    }
}

struct MessageInsert: Encodable {
    let id: UUID
    let classId: UUID
    let role: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case id
        case classId = "class_id"
        case role, content
    }
}
