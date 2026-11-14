import Foundation

enum AppError: LocalizedError, Equatable {
    case network
    case missingSupabase
    case wrongPassword
    case emailTaken
    case weakPassword
    case droppedCarrot
    case custom(String)

    var bunnyMessage: String {
        switch self {
        case .network:
            return "I hopped into a rabbit hole and lost the signal. Check your internet and try again?"
        case .missingSupabase:
            return "My burrow map is missing! Add SUPABASE_URL and SUPABASE_ANON_KEY to Secrets.xcconfig."
        case .wrongPassword:
            return "That email and password didn’t open the garden gate. Try again?"
        case .emailTaken:
            return "That email already has a burrow. Try signing in, or use a different email."
        case .weakPassword:
            return "That password is a bit too nibble-sized. Use at least 6 characters."
        case .droppedCarrot:
            return "Oops, the bunny dropped the carrot! Try again."
        case .custom(let message):
            return message
        }
    }

    var errorDescription: String? { bunnyMessage }

    static func from(_ error: Error) -> AppError {
        if let app = error as? AppError { return app }
        if error is MaterialProcessError { return .custom((error as! MaterialProcessError).bunnyMessage) }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost:
                return .network
            default:
                break
            }
        }

        let text = error.localizedDescription.lowercased()
        if text.contains("missing supabase") { return .missingSupabase }
        if text.contains("invalid login") || text.contains("invalid credentials") || text.contains("invalid_grant") {
            return .wrongPassword
        }
        if text.contains("already registered") || text.contains("already been registered") || text.contains("user already exists") {
            return .emailTaken
        }
        if text.contains("password") && (text.contains("weak") || text.contains("at least") || text.contains("6")) {
            return .weakPassword
        }
        if text.contains("network") || text.contains("offline") || text.contains("internet") {
            return .network
        }
        return .droppedCarrot
    }
}
