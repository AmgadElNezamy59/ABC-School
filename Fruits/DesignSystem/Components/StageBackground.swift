import SwiftUI

/// The colorful rounded "stage" every word stands on.
/// Looks the same in light and dark mode, like an illustration.
struct StageBackground: View {
    let colors: [Color]
    var cornerRadius: CGFloat = Radius.large

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                // Two soft "bubbles" give every stage the same playful signature.
                GeometryReader { proxy in
                    let side = max(proxy.size.width, proxy.size.height)
                    Circle()
                        .fill(.white.opacity(0.16))
                        .frame(width: side * 0.7)
                        .offset(x: -side * 0.28, y: -side * 0.34)
                    Circle()
                        .fill(.white.opacity(0.10))
                        .frame(width: side * 0.5)
                        .offset(x: proxy.size.width - side * 0.22, y: proxy.size.height - side * 0.26)
                }
                .clipShape(shape)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    StageBackground(colors: ["#EF5350", "#C62F3E"].gradientColors)
        .frame(width: 240, height: 240)
        .padding()
}
