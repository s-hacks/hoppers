import SwiftUI

struct ProfileSheet: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                HoppersBackground()
                VStack(spacing: 20) {
                    BunnyView(state: .happy, size: 120)
                        .padding(.top, 12)

                    Text(auth.userEmail ?? "Hopper")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(HoppersTheme.plum)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button {
                        Task {
                            await auth.signOut()
                            dismiss()
                        }
                    } label: {
                        Text("Sign out")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(HoppersTheme.plum)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.light)
    }
}

#Preview("Profile") {
    ProfileSheet()
        .environmentObject(AuthViewModel())
}
