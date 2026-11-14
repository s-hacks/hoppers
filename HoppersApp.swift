import SwiftUI

@main
struct HoppersApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var services = HoppersServices.live

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(services)
                .task {
                    await auth.start()
                }
        }
    }
}
