import SwiftUI

struct BunnyLoadingView: View {
    var message: String = "Checking the burrow…"

    var body: some View {
        ZStack {
            HoppersBackground()
            VStack(spacing: 16) {
                BunnyView(state: .thinking, size: 160)
                Text(message)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(HoppersTheme.plum)
            }
        }
        .font(.system(.body, design: .rounded))
    }
}

#Preview("Loading") {
    BunnyLoadingView()
}
