import SwiftUI

/// A toy-like 3D button that presses down. The app's primary action style.
struct ChunkyButtonStyle: ButtonStyle {
    enum Shape { case rounded, circle }

    var color: Color = .brand
    var foreground: Color = .white
    var shape: Shape = .rounded

    func makeBody(configuration: Configuration) -> some View {
        ChunkyButton(label: configuration.label, isPressed: configuration.isPressed,
                     color: color, foreground: foreground, shape: shape)
    }
}

private struct ChunkyButton<Label: View>: View {
    let label: Label
    let isPressed: Bool
    let color: Color
    let foreground: Color
    let shape: ChunkyButtonStyle.Shape

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let depth: CGFloat = 5

    private var outline: AnyShape {
        switch shape {
        case .rounded: AnyShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        case .circle: AnyShape(Circle())
        }
    }

    var body: some View {
        label
            .font(.headline.weight(.bold))
            .foregroundStyle(foreground)
            // Buttons stay on one line; long labels shrink a little instead of wrapping.
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, shape == .circle ? 0 : Spacing.m)
            .frame(minWidth: 56, minHeight: 56)
            .background(outline.fill(color))
            .contentShape(outline)
            // The face moves down onto its base when pressed.
            .offset(y: isPressed ? depth : 0)
            .background(
                outline.fill(color)
                    .overlay(outline.fill(Color.black.opacity(0.22)))
                    .offset(y: depth)
            )
            .padding(.bottom, depth)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.65), value: isPressed)
    }
}

/// Gentle shrink on press, for cards and tiles.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A small round icon button with a caption under it, e.g. "Slow" or "Say it".
struct CaptionedIconButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    var color: Color = .surface
    var foreground: Color = .brand
    var isActive = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.bold))
                    .symbolEffect(.variableColor.iterative, isActive: isActive)
                    .frame(width: 64, height: 64)
            }
            .buttonStyle(ChunkyButtonStyle(color: color, foreground: foreground, shape: .circle))
            .accessibilityLabel(Text(title))

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.inkSecondary)
                .accessibilityHidden(true)
        }
    }
}
