import SwiftUI

/// Draws a word's picture at any size: photo, emoji, letters, number, color swatch or shape.
/// Decorative for VoiceOver; the surrounding control carries the label.
struct WordVisualView: View {
    let visual: WordVisual

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            content(side: side)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func content(side: CGFloat) -> some View {
        switch visual {
        case .photo(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .padding(side * 0.06)
                .shadow(color: .black.opacity(0.18), radius: side * 0.03, x: 0, y: side * 0.02)

        case .emoji(let emoji):
            Text(verbatim: emoji)
                .font(.system(size: side * 0.56, design: .default))
                .shadow(color: .black.opacity(0.12), radius: side * 0.02, x: 0, y: side * 0.015)

        case .text(let value, let badge):
            ZStack(alignment: .bottomTrailing) {
                Text(verbatim: value)
                    .font(.system(size: side * 0.44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: side * 0.015)
                    .frame(width: side, height: side)
                if let badge {
                    Text(verbatim: badge)
                        .font(.system(size: side * 0.15))
                        .padding(side * 0.045)
                        .background(Circle().fill(.white))
                        .shadow(color: .black.opacity(0.15), radius: side * 0.02, x: 0, y: side * 0.01)
                        .padding(side * 0.03)
                }
            }

        case .number(let value):
            VStack(spacing: side * 0.06) {
                Text(verbatim: String(value))
                    .font(.system(size: side * 0.36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: side * 0.015)
                TenFrame(count: value, dotSpacing: side * 0.025)
                    .frame(width: side * 0.66)
            }

        case .color(let hex):
            Circle()
                .fill(HexColor(hex)?.color ?? .gray)
                .overlay(Circle().strokeBorder(.black.opacity(0.08), lineWidth: max(1, side * 0.012)))
                .frame(width: side * 0.62, height: side * 0.62)
                .shadow(color: .black.opacity(0.18), radius: side * 0.03, x: 0, y: side * 0.02)

        case .shape(let symbol):
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: side * 0.56, height: side * 0.56)
                .shadow(color: .black.opacity(0.18), radius: side * 0.02, x: 0, y: side * 0.015)
        }
    }
}

/// Ten dots in two rows of five; the first `count` are filled. A classic way to see quantities.
struct TenFrame: View {
    let count: Int
    var dotSpacing: CGFloat = 4

    var body: some View {
        Grid(horizontalSpacing: dotSpacing, verticalSpacing: dotSpacing) {
            ForEach(0..<2, id: \.self) { row in
                GridRow {
                    ForEach(0..<5, id: \.self) { column in
                        Circle()
                            .fill(row * 5 + column < count ? Color.white : Color.white.opacity(0.25))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
}

#Preview {
    let visuals: [WordVisual] = [
        .photo("apple"), .emoji("🦁"), .text("Aa", badge: "🍎"),
        .number(7), .color("#E53935"), .shape("star.fill"),
    ]
    return LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
        ForEach(Array(visuals.enumerated()), id: \.offset) { _, visual in
            ZStack {
                StageBackground(colors: ["#6C5CE7", "#4B3BC4"].gradientColors, cornerRadius: Radius.medium)
                WordVisualView(visual: visual)
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
    .padding()
}
