import SwiftUI

/// Filled and empty stars, read by VoiceOver as "2 of 3 stars".
struct StarsView: View {
    let count: Int
    var maximum = ProgressStore.maxStars
    var size: CGFloat = 14
    var emptyColor: Color = Color.inkSecondary.opacity(0.35)

    var body: some View {
        HStack(spacing: size * 0.2) {
            ForEach(0..<maximum, id: \.self) { index in
                Image(systemName: index < count ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(index < count ? Color.star : emptyColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(count) of \(maximum) stars"))
    }
}

/// A rounded progress track. Decorative; the parent provides the spoken value.
struct ProgressBar: View {
    let value: Double
    var tint: Color = .brand
    var track: Color = .surfaceMuted
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
        .accessibilityHidden(true)
    }
}

/// Total stars, shown in the Home toolbar.
struct StarCountBadge: View {
    let count: Int

    var body: some View {
        // An HStack, not a Label: toolbars on iOS 26 show labels as icon-only.
        HStack(spacing: Spacing.xxs + 2) {
            Image(systemName: "star.fill")
                .foregroundStyle(Color.star)
            Text(count, format: .number)
                .contentTransition(.numericText())
        }
        .font(.headline.weight(.heavy))
        .foregroundStyle(Color.ink)
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xxs + 2)
        .background(Color.surface, in: Capsule())
        .animation(.snappy, value: count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(count) stars earned"))
    }
}

#Preview {
    VStack(spacing: 20) {
        StarsView(count: 2, size: 28)
        ProgressBar(value: 0.6).frame(width: 200)
        StarCountBadge(count: 42)
    }
    .padding()
    .background(Color.appBackground)
}
