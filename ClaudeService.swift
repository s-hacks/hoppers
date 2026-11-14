import Foundation

/// Talks to the Anthropic Messages API over URLSession.
struct ClaudeService {
    /// Sonnet 4.6: strong tutoring quality, thinking off by default so replies
    /// actually include text. Sonnet 5.5 keeps thinking on and can burn the
    /// whole token budget before writing a message.
    static let model = "claude-sonnet-4-6"
    static let maxTokens = 2048
    static let anthropicVersion = "2023-06-01"
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private let session: URLSession
    private let apiKeyProvider: () -> String

    init(
        session: URLSession = .shared,
        apiKeyProvider: (() -> String)? = nil
    ) {
        self.session = session
        self.apiKeyProvider = apiKeyProvider ?? { Secrets.anthropicAPIKey }
    }

    func complete(
        classItem: ClassItem,
        history: [Message],
        materials: [Material],
        imageBytes: [UUID: Data]
    ) async throws -> String {
        let apiKey = apiKeyProvider()
        guard !apiKey.isEmpty else {
            throw ClaudeError.missingAPIKey
        }

        let imageMaterials = materials
            .filter { $0.type == .image && imageBytes[$0.id] != nil }
            .prefix(MaterialProcessor.maxImagesPerRequest)

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = imageMaterials.isEmpty ? 60 : 120
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let recent = Array(history.suffix(30))
        let body = ClaudeRequest(
            model: Self.model,
            max_tokens: Self.maxTokens,
            system: systemPrompt(for: classItem, materials: materials),
            messages: apiMessages(from: recent, images: Array(imageMaterials), imageBytes: imageBytes)
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw ClaudeError.invalidRequest
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ClaudeError.network
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let decoded = try? JSONDecoder().decode(ClaudeResponse.self, from: data)

        if (200..<300).contains(status) {
            if let text = decoded?.content?
                .compactMap(\.text)
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty {
                return text
            }
            throw ClaudeError.invalidResponse
        }

        let serverMessage = decoded?.error?.message
        throw ClaudeError.server(status: status, message: serverMessage)
    }

    private func systemPrompt(for classItem: ClassItem, materials: [Material]) -> String {
        let materialsBlock = MaterialProcessor.materialsContext(from: materials)
        let materialsInstruction = """
        Use the student's class materials to guide your hints and match their course's terminology and methods. Never give final answers to the student's problems, even if the answer appears in the materials. Reference materials by name when helpful, like 'check your notes on photosynthesis'.
        """

        return """
        \(SystemPrompt.text)

        You are \(classItem.botName), the tutor for the student's \(classItem.name) class.
        \(materialsInstruction)
        \(materialsBlock)
        """
    }

    private func apiMessages(
        from history: [Message],
        images: [Material],
        imageBytes: [UUID: Data]
    ) -> [ClaudeRequest.APIMessage] {
        var payload = history
            .filter { !$0.isLocalOnly && !$0.isError }
            .sorted { $0.createdAt < $1.createdAt }
            .map { message -> ClaudeRequest.APIMessage in
                ClaudeRequest.APIMessage(
                    role: message.role.rawValue,
                    content: .text(message.text)
                )
            }

        while payload.first?.role == "assistant" {
            payload.removeFirst()
        }

        if !images.isEmpty, let firstUser = payload.firstIndex(where: { $0.role == "user" }) {
            var parts: [ClaudeRequest.APIMessage.Part] = images.compactMap { material in
                guard let data = imageBytes[material.id] else { return nil }
                return .imageJPEG(base64: data.base64EncodedString())
            }
            if case .text(let text) = payload[firstUser].content {
                parts.append(.text(text))
            }
            payload[firstUser].content = .parts(parts)
        }

        return payload
    }
}

enum ClaudeError: LocalizedError {
    case missingAPIKey
    case invalidRequest
    case invalidResponse
    case network
    case server(status: Int, message: String?)

    /// Friendly, bunny-themed copy shown in the chat bubble.
    var bunnyMessage: String {
        switch self {
        case .missingAPIKey:
            return "Oh carrots — I can’t find my API key! Add your Anthropic key to Secrets.plist (or the ANTHROPIC_API_KEY Info.plist entry) and I’ll hop right back."
        case .network:
            return "I hopped into a rabbit hole and lost the signal. Check your internet and send that again?"
        case .invalidRequest:
            return "My whiskers got tangled packing that question. Try sending it one more time?"
        case .invalidResponse:
            return "I got a reply that smelled like empty carrot greens. Want to try again?"
        case .server(let status, let message):
            if status == 401 || status == 403 {
                return "That API key didn’t open the garden gate. Double-check it in Secrets.plist and hop back."
            }
            if let message, !message.isEmpty {
                return "Carrot crumbs! (\(status)) \(message)"
            }
            return "Carrot crumbs — the tutor burrow returned \(status). Let’s try that hop again."
        }
    }
}

private struct ClaudeRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [APIMessage]

    struct APIMessage: Encodable {
        let role: String
        var content: Content

        enum Content: Encodable {
            case text(String)
            case parts([Part])

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .text(let value):
                    try container.encode(value)
                case .parts(let parts):
                    try container.encode(parts)
                }
            }
        }

        enum Part: Encodable {
            case text(String)
            case imageJPEG(base64: String)

            enum CodingKeys: String, CodingKey {
                case type, text, source
            }

            enum SourceKeys: String, CodingKey {
                case type, media_type, data
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .text(let text):
                    try container.encode("text", forKey: .type)
                    try container.encode(text, forKey: .text)
                case .imageJPEG(let base64):
                    try container.encode("image", forKey: .type)
                    var source = container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source)
                    try source.encode("base64", forKey: .type)
                    try source.encode("image/jpeg", forKey: .media_type)
                    try source.encode(base64, forKey: .data)
                }
            }
        }
    }
}

private struct ClaudeResponse: Decodable {
    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }

    struct APIError: Decodable {
        let type: String?
        let message: String?
    }

    let content: [ContentBlock]?
    let error: APIError?
}
