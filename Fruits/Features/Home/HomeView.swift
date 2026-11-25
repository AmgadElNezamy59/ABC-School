import SwiftUI

/// Topic picker: the app's starting point.
struct HomeView: View {
    let categories: [Category]

    @Environment(ProgressStore.self) private var progress
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var path: [Route] = []
    @State private var showsSettings = false

    private var isRegular: Bool { sizeClass == .regular }

    private var columns: [GridItem] {
        // Very large text gets one full-width card per row so nothing truncates.
        if dynamicTypeSize.isAccessibilitySize && !isRegular {
            return [GridItem(.flexible())]
        }
        return [GridItem(.adaptive(minimum: isRegular ? 240 : 158, maximum: 320), spacing: Spacing.m)]
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    header

                    LazyVGrid(columns: columns, spacing: Spacing.m) {
                        ForEach(categories) { category in
                            NavigationLink(value: Route.topic(category)) {
                                CategoryCard(category: category,
                                             practiced: progress.practicedCount(in: category),
                                             isLarge: isRegular)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .accessibilityIdentifier("topic.\(category.id)")
                        }
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, Spacing.xl)
                .frame(maxWidth: 960)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("ABC School")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("home.settings")
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .topic(let category):
                    TopicView(category: category)
                case .learn(let category, let startIndex):
                    LearnView(category: category, startIndex: startIndex)
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
            }
        }
    }

    /// The prompt and the child's star total, side by side (stacked for very large text).
    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.s))
        return layout {
            Text("Pick a topic, listen, then say it!")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            StarCountBadge(count: progress.totalStars)
                .softShadow()
                .accessibilityIdentifier("home.stars")
        }
    }
}

/// A topic tile on Home: gradient, cover picture, name and progress.
struct CategoryCard: View {
    let category: Category
    let practiced: Int
    /// Bigger cards on iPad and other regular-width layouts.
    var isLarge = false

    private var total: Int { category.words.count }
    private var coverSize: CGFloat { isLarge ? 128 : 96 }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Keeps the text clear of the cover picture; the card grows with large text.
            Spacer(minLength: coverSize * 0.75)
            Text(verbatim: category.title)
                .font(.title2.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(practiced) of \(total) words")
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            ProgressBar(value: Double(practiced) / Double(max(total, 1)), tint: .white, track: .white.opacity(0.3))
        }
        .foregroundStyle(.white)
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, minHeight: isLarge ? 240 : 184, alignment: .bottomLeading)
        .background(alignment: .topTrailing) {
            WordVisualView(visual: category.cover)
                .frame(width: coverSize, height: coverSize)
                .rotationEffect(.degrees(8))
                .padding(Spacing.xs)
        }
        .background(StageBackground(colors: category.colors.gradientColors))
        .softShadow()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: category.title))
        .accessibilityValue(Text("\(practiced) of \(total) words practiced"))
    }
}

#Preview {
    HomeView(categories: PreviewSupport.categories)
        .previewEnvironment()
}
