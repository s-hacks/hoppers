import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                BunnyLoadingView()
            case .signedOut:
                AuthView()
            case .signedIn:
                NavigationStack {
                    ClassListView()
                }
            }
        }
        .tint(HoppersTheme.plum)
        .font(.system(.body, design: .rounded))
        .preferredColorScheme(.light)
        .animation(HoppersTheme.softSpring, value: auth.state)
    }
}

#Preview("App signed out") {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(HoppersServices.preview)
}
