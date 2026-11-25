import SwiftUI

/// One topic: progress, the two ways in (Learn and Play), and every word.
struct TopicView: View {
    let category: Category

    @Environment(ProgressStore.self) private var progress
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsGame = false

    private var columns: [GridItem] {
        let minimum: CGFloat = sizeClass == .regular || dynamicTypeSize.isAccessibilitySize ? 150 : 104
        return [GridItem(.adaptive(minimum: minimum, maximum: 200), spacing: Spacing.s)]
    }

    /// Learning resumes at the first word without stars.
    private var resumeIndex: Int {
        category.words.firstIndex { progress.stars(for: $0) == 0 } ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                header
                actions
                LazyVGrid(columns: columns, spacing: Spacing.s) {
                    ForEach(Array(category.words.enumerated()), id: \.element.id) { index, word in
                        NavigationLink(value: Route.learn(category, startIndex: index)) {
                            WordTile(word: word,
                                     colors: (word.colors ?? category.colors).gradientColors,
                                     stars: progress.stars(for: word))
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityIdentifier("word.\(word.id)")
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: category.title))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showsGame) {
            GameView(category: category)
        }
    }

    private var header: some View {
        let practiced = progress.practicedCount(in: category)
        let total = category.words.count
        return HStack(spacing: Spacing.m) {
            WordVisualView(visual: category.cover)
                .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(practiced) of \(total) words practiced")
                    .font(.headline.weight(.heavy))
                ProgressBar(value: Double(practiced) / Double(max(total, 1)), tint: .white, track: .white.opacity(0.3), height: 10)
                if let best = progress.bestGame(for: category) {
                    Label("Best game: \(best.correct) of \(best.total)", systemImage: "trophy.fill")
                        .font(.subheadline.weight(.bold))
                }
            }
            .foregroundStyle(.white)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StageBackground(colors: category.colors.gradientColors))
        .softShadow()
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        HStack(spacing: Spacing.s) {
            NavigationLink(value: Route.learn(category, startIndex: resumeIndex)) {
                Label("Learn", systemImage: "rectangle.stack.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(color: .brand))
            .accessibilityHint("Listen to the words one by one")
            .accessibilityIdentifier("topic.learn")

            Button {
                showsGame = true
            } label: {
                Label("Play", systemImage: "gamecontroller.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(color: .success))
            .accessibilityHint("Hear a word and find its picture")
            .accessibilityIdentifier("topic.play")
        }
    }
}

/// A word in the topic grid.
struct WordTile: View {
    let word: Word
    let colors: [Color]
    let stars: Int

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                StageBackground(colors: colors, cornerRadius: Radius.medium)
                WordVisualView(visual: word.visual)
                    .padding(Spacing.xxs)
            }
            .aspectRatio(1, contentMode: .fit)

            Text(verbatim: word.text)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            StarsView(count: stars, size: 11)
        }
        .padding(Spacing.xs)
        .padding(.bottom, Spacing.xxs)
        .surfaceCard(radius: Radius.medium + Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: word.text))
        .accessibilityValue(Text("\(stars) of \(ProgressStore.maxStars) stars"))
    }
}

#Preview {
    NavigationStack {
        TopicView(category: PreviewSupport.fruits)
    }
    .previewEnvironment()
}
