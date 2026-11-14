import SwiftUI

/// A reusable bunny mascot drawn from SwiftUI shapes.
struct BunnyView: View {
    var state: BunnyState = .idle
    var size: CGFloat = 180

    @State private var wiggle = false
    @State private var hop = false
    @State private var breathe = false

    private var compact: Bool { size < 56 }

    var body: some View {
        ZStack {
            bodyAndShadow
            ears
            head
            face
            if !compact {
                paws
            }
            if state == .sleepy && !compact {
                sleepyZzz
            }
        }
        .frame(width: 200, height: 200)
        .scaleEffect(size / 200)
        .frame(width: size, height: size)
        .scaleEffect(idleScale)
        .offset(y: hopOffset)
        .onAppear { startMotion(for: state) }
        .onChange(of: state) { _, newState in
            startMotion(for: newState)
        }
        .accessibilityLabel("Hoppers the bunny, \(state.rawValue)")
    }

    private var idleScale: CGFloat {
        if state == .idle || state == .sleepy { return breathe ? 1.04 : 1.0 }
        if state == .happy { return hop ? 1.06 : 1.0 }
        return 1.0
    }

    private var hopOffset: CGFloat {
        state == .happy && hop ? -8 : 0
    }

    private var bodyAndShadow: some View {
        ZStack {
            Ellipse()
                .fill(HoppersTheme.plum.opacity(0.12))
                .frame(width: 108, height: 20)
                .offset(y: 86)

            Ellipse()
                .fill(HoppersTheme.bunnyFur)
                .frame(width: 112, height: 96)
                .offset(y: 42)
                .shadow(color: HoppersTheme.plum.opacity(0.12), radius: 8, y: 4)

            Ellipse()
                .fill(HoppersTheme.cream)
                .frame(width: 68, height: 56)
                .offset(y: 50)
        }
    }

    private var ears: some View {
        ZStack {
            ear(isLeft: true)
                .offset(x: -30, y: -78)
            ear(isLeft: false)
                .offset(x: 30, y: -78)
        }
    }

    private func ear(isLeft: Bool) -> some View {
        let rest: Double = isLeft ? -18 : 18
        let extra: Double = {
            guard state == .thinking else { return 0 }
            let amount: Double = wiggle ? 12 : -9
            return isLeft ? -amount : amount
        }()

        return ZStack {
            Capsule()
                .fill(HoppersTheme.bunnyFur)
                .frame(width: 32, height: 92)
                .shadow(color: HoppersTheme.plum.opacity(0.1), radius: 4, y: 2)
            Capsule()
                .fill(HoppersTheme.innerEar)
                .frame(width: 16, height: 64)
                .offset(y: 6)
        }
        .rotationEffect(.degrees(rest + extra), anchor: .bottom)
    }

    private var head: some View {
        Circle()
            .fill(HoppersTheme.bunnyFur)
            .frame(width: 118, height: 118)
            .offset(y: -16)
            .shadow(color: HoppersTheme.plum.opacity(0.1), radius: 6, y: 3)
    }

    private var face: some View {
        ZStack {
            // Cheeks
            Circle()
                .fill(HoppersTheme.blushPink.opacity(state == .happy ? 0.95 : 0.7))
                .frame(width: state == .happy ? 26 : 22, height: state == .happy ? 18 : 16)
                .offset(x: -34, y: 6)
            Circle()
                .fill(HoppersTheme.blushPink.opacity(state == .happy ? 0.95 : 0.7))
                .frame(width: state == .happy ? 26 : 22, height: state == .happy ? 18 : 16)
                .offset(x: 34, y: 6)

            eyes

            // Nose
            Capsule()
                .fill(HoppersTheme.innerEar)
                .frame(width: 14, height: 10)
                .offset(y: 10)

            // Mouth
            mouth
                .offset(y: 22)

            if !compact {
                whiskers
            }
        }
        .offset(y: -16)
    }

    @ViewBuilder
    private var eyes: some View {
        if state == .happy {
            HStack(spacing: 28) {
                happyEye(flip: false)
                happyEye(flip: true)
            }
            .offset(y: -10)
        } else if state == .sleepy {
            HStack(spacing: 26) {
                Capsule()
                    .fill(HoppersTheme.plum)
                    .frame(width: 16, height: 3)
                Capsule()
                    .fill(HoppersTheme.plum)
                    .frame(width: 16, height: 3)
            }
            .offset(y: -8)
        } else {
            HStack(spacing: 26) {
                roundEye(lookUp: state == .thinking)
                roundEye(lookUp: state == .thinking)
            }
            .offset(y: -12)
        }
    }

    private func roundEye(lookUp: Bool) -> some View {
        ZStack {
            Circle()
                .fill(HoppersTheme.plum)
                .frame(width: 16, height: 16)
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .offset(x: 3, y: lookUp ? -4 : -2)
        }
    }

    private func happyEye(flip: Bool) -> some View {
        Capsule()
            .stroke(HoppersTheme.plum, lineWidth: 3.5)
            .frame(width: 16, height: 10)
            .rotationEffect(.degrees(flip ? 18 : -18))
            .offset(y: 2)
    }

    @ViewBuilder
    private var mouth: some View {
        if state == .happy {
            Capsule()
                .stroke(HoppersTheme.plum.opacity(0.75), lineWidth: 2.5)
                .frame(width: 16, height: 10)
                .offset(y: 4)
        } else {
            HStack(spacing: 0) {
                Capsule()
                    .stroke(HoppersTheme.plum.opacity(0.7), lineWidth: 2)
                    .frame(width: 8, height: 6)
                Capsule()
                    .stroke(HoppersTheme.plum.opacity(0.7), lineWidth: 2)
                    .frame(width: 8, height: 6)
            }
        }
    }

    private var whiskers: some View {
        ZStack {
            ForEach([-1, 1], id: \.self) { side in
                VStack(spacing: 7) {
                    whisker.rotationEffect(.degrees(Double(side) * -12))
                    whisker
                    whisker.rotationEffect(.degrees(Double(side) * 12))
                }
                .offset(x: CGFloat(side) * 46, y: 10)
            }
        }
    }

    private var whisker: some View {
        Capsule()
            .fill(HoppersTheme.plum.opacity(0.28))
            .frame(width: 22, height: 1.4)
    }

    private var paws: some View {
        HStack(spacing: 40) {
            paw
            paw
        }
        .offset(y: 72)
    }

    private var paw: some View {
        Capsule()
            .fill(HoppersTheme.bunnyFur)
            .frame(width: 28, height: 22)
            .overlay(
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(HoppersTheme.innerEar.opacity(0.7))
                            .frame(width: 4, height: 7)
                    }
                }
                .offset(y: -2)
            )
            .shadow(color: HoppersTheme.plum.opacity(0.08), radius: 2, y: 1)
    }

    private func startMotion(for state: BunnyState) {
        wiggle = false
        hop = false
        breathe = false

        switch state {
        case .idle:
            guard !compact else { return }
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                breathe = true
            }
        case .thinking:
            withAnimation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true)) {
                wiggle = true
            }
        case .happy:
            withAnimation(.spring(response: 0.38, dampingFraction: 0.42).repeatForever(autoreverses: true)) {
                hop = true
            }
        case .sleepy:
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    private var sleepyZzz: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("z")
                .offset(x: 8)
            Text("z")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .offset(x: 18, y: -4)
            Text("Z")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .offset(x: 30, y: -8)
        }
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .foregroundStyle(HoppersTheme.lavender)
        .offset(x: 58, y: -70)
        .opacity(breathe ? 1 : 0.45)
    }
}

#Preview("Bunny moods") {
    ZStack {
        HoppersBackground()
        HStack(spacing: 20) {
            ForEach(BunnyState.allCases, id: \.self) { state in
                VStack(spacing: 8) {
                    BunnyView(state: state, size: 120)
                    Text(state.rawValue)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(HoppersTheme.plum)
                }
            }
        }
    }
}
