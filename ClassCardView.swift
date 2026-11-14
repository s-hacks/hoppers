import SwiftUI

struct ClassCardView: View {
    let classItem: ClassItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(classItem.emoji)
                .font(.system(size: 40))
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text(classItem.botName)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(HoppersTheme.plum)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(classItem.materialsSubtitle)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(HoppersTheme.plum.opacity(0.65))
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 168)
        .background(classItem.color)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .hoppersShadow(0.12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(classItem.botName), \(classItem.materialsSubtitle)")
    }
}

struct AddClassCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("Add a class")
                .font(.system(.headline, design: .rounded).weight(.bold))
        }
        .foregroundStyle(HoppersTheme.plum.opacity(0.7))
        .frame(maxWidth: .infinity, minHeight: 168)
        .background(Color.white.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    HoppersTheme.plum.opacity(0.35),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
        )
        .accessibilityLabel("Add a class")
    }
}

#Preview("Class card") {
    ZStack {
        HoppersBackground()
        ClassCardView(classItem: HoppersPreviewData.history)
            .padding(40)
    }
}

#Preview("Add card") {
    ZStack {
        HoppersBackground()
        AddClassCard()
            .padding(40)
    }
}
