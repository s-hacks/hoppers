import Combine
import Foundation

@MainActor
final class HoppersServices: ObservableObject {
    let classes: any ClassRepository
    let messages: any MessageRepository
    let materials: any MaterialRepository
    let claude: ClaudeService

    init(
        classes: any ClassRepository,
        messages: any MessageRepository,
        materials: any MaterialRepository,
        claude: ClaudeService = ClaudeService()
    ) {
        self.classes = classes
        self.messages = messages
        self.materials = materials
        self.claude = claude
    }

    static var live: HoppersServices {
        HoppersServices(
            classes: SupabaseClassRepository(),
            messages: SupabaseMessageRepository(),
            materials: SupabaseMaterialRepository()
        )
    }

    static var preview: HoppersServices {
        HoppersServices(
            classes: MockClassRepository(),
            messages: MockMessageRepository(),
            materials: MockMaterialRepository()
        )
    }
}
