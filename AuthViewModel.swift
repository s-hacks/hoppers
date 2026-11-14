import AuthenticationServices
import Combine
import Foundation
import Supabase

enum AuthState: Equatable {
    case loading
    case signedOut
    case signedIn
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var state: AuthState = .loading
    @Published var email = ""
    @Published var password = ""
    @Published var isSignUp = false
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published var userEmail: String?

    func start() async {
        guard Secrets.hasSupabaseConfig else {
            state = .signedOut
            errorMessage = AppError.missingSupabase.bunnyMessage
            return
        }

        for await (_, session) in SupabaseManager.client.auth.authStateChanges {
            apply(session: session)
        }
    }

    func hopIn() async {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Leave an email and password in the burrow so I can hop you in."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            if isSignUp {
                let response = try await SupabaseManager.client.auth.signUp(
                    email: trimmedEmail,
                    password: password
                )
                if response.session == nil {
                    errorMessage = "Almost hopped in! If email confirmation is on, check your inbox, then Sign in."
                }
            } else {
                try await SupabaseManager.client.auth.signIn(
                    email: trimmedEmail,
                    password: password
                )
            }
        } catch {
            errorMessage = AppError.from(error).bunnyMessage
        }
    }

    func signInWithApple(idToken: String) async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            try await SupabaseManager.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken)
            )
        } catch {
            errorMessage = AppError.from(error).bunnyMessage
        }
    }

    func signOut() async {
        do {
            try await SupabaseManager.client.auth.signOut()
        } catch {
            errorMessage = AppError.from(error).bunnyMessage
        }
    }

    private func apply(session: Session?) {
        if let session {
            state = .signedIn
            userEmail = session.user.email
            errorMessage = nil
        } else {
            state = .signedOut
            userEmail = nil
        }
    }
}
