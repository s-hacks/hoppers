import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    var body: some View {
        ZStack {
            HoppersBackground()

            ScrollView {
                VStack(spacing: 20) {
                    BunnyView(state: auth.isBusy ? .thinking : .idle, size: 150)
                        .padding(.top, 24)

                    Text("Welcome to Hoppers")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(HoppersTheme.plum)
                        .multilineTextAlignment(.center)

                    Text(auth.isSignUp ? "Create a burrow to start learning" : "Hop back in to your classes")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(HoppersTheme.plum.opacity(0.7))

                    VStack(spacing: 12) {
                        TextField("Email", text: $auth.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .hoppersField()

                        SecureField("Password", text: $auth.password)
                            .textContentType(auth.isSignUp ? .newPassword : .password)
                            .focused($focusedField, equals: .password)
                            .hoppersField()
                    }
                    .padding(.horizontal, 24)

                    if let errorMessage = auth.errorMessage {
                        Text(errorMessage)
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundStyle(HoppersTheme.plum)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(HoppersTheme.blushPink.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.horizontal, 24)
                    }

                    Button {
                        Task { await auth.hopIn() }
                    } label: {
                        HStack {
                            if auth.isBusy {
                                ProgressView().tint(.white)
                            }
                            Text("Hop In")
                        }
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(HoppersTheme.plum)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .shadow(color: HoppersTheme.plum.opacity(0.28), radius: 14, y: 8)
                    }
                    .disabled(auth.isBusy)
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        Task { await handleApple(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 24)

                    Button {
                        withAnimation(HoppersTheme.spring) {
                            auth.isSignUp.toggle()
                            auth.errorMessage = nil
                        }
                    } label: {
                        Text(auth.isSignUp ? "Already have a burrow? Sign in" : "New here? Create account")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(HoppersTheme.plum)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .font(.system(.body, design: .rounded))
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            auth.errorMessage = AppError.from(error).bunnyMessage
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8)
            else {
                auth.errorMessage = AppError.droppedCarrot.bunnyMessage
                return
            }
            await auth.signInWithApple(idToken: token)
        }
    }
}

private extension View {
    func hoppersField() -> some View {
        self
            .font(.system(.body, design: .rounded))
            .foregroundStyle(HoppersTheme.plum)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(HoppersTheme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(HoppersTheme.lavender.opacity(0.6), lineWidth: 1.5)
            )
    }
}

#Preview("Auth") {
    AuthView()
        .environmentObject(AuthViewModel())
}
