import SwiftUI

/// Swipeable word cards with a fixed control bar: Slow · Listen · Say it.
struct LearnView: View {
    let category: Category

    @Environment(Speaker.self) private var speaker
    @Environment(AppSettings.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @State private var index: Int
    @State private var practiceWord: Word?

    init(category: Category, startIndex: Int) {
        self.category = category
        _index = State(initialValue: min(max(startIndex, 0), max(category.words.count - 1, 0)))
    }

    private var currentWord: Word? {
        category.words.indices.contains(index) ? category.words[index] : nil
    }

    private func colors(for word: Word) -> [Color] {
        (word.colors ?? category.colors).gradientColors
    }

    var body: some View {
        VStack(spacing: Spacing.s) {
            TabView(selection: $index) {
                ForEach(Array(category.words.enumerated()), id: \.element.id) { offset, word in
                    WordCardView(word: word, colors: colors(for: word), stars: progress.stars(for: word))
                        .padding(.horizontal, Spacing.m)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // The control bar keeps a fixed footprint; its icons carry the meaning and
            // VoiceOver reads full labels, so it stops growing at the largest standard size.
            Group {
                if let word = currentWord {
                    controls(for: word)
                }
                pager
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(.bottom, Spacing.xs)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: category.title))
        .navigationBarTitleDisplayMode(.inline)
        // The title already names the topic, so the back button needs no label.
        .toolbarRole(.editor)
        .task(id: index) { await autoplayCurrentWord() }
        .onDisappear { speaker.stop() }
        .sheet(item: $practiceWord) { word in
            PracticeView(word: word, colors: colors(for: word))
        }
    }

    private func controls(for word: Word) -> some View {
        HStack(alignment: .top, spacing: Spacing.l) {
            CaptionedIconButton(title: "Slow", systemImage: "tortoise.fill",
                                isActive: speaker.isPlaying(Speaker.tag(for: word, speed: .slow))) {
                speaker.play(word, speed: .slow)
            }
            .accessibilityIdentifier("learn.slow")

            Button {
                speaker.play(word)
            } label: {
                Label {
                    Text("Listen")
                } icon: {
                    Image(systemName: "speaker.wave.2.fill")
                        .symbolEffect(.variableColor.iterative,
                                      isActive: speaker.isPlaying(Speaker.tag(for: word, speed: .normal)))
                }
                .font(.title3.weight(.heavy))
                .frame(minWidth: 132, minHeight: 64)
            }
            .buttonStyle(ChunkyButtonStyle(color: .brand))
            .accessibilityIdentifier("learn.listen")

            CaptionedIconButton(title: "Say it", systemImage: "mic.fill", color: .attention, foreground: .white) {
                speaker.stop()
                practiceWord = word
            }
            .accessibilityIdentifier("learn.sayIt")
        }
        .padding(.horizontal, Spacing.m)
    }

    private var pager: some View {
        HStack {
            Button {
                withAnimation { index -= 1 }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(index == 0)
            .accessibilityLabel("Previous word")
            .accessibilityIdentifier("learn.previous")

            Spacer()

            Text("\(index + 1) of \(category.words.count)")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.inkSecondary)
                .accessibilityIdentifier("learn.counter")

            Spacer()

            Button {
                withAnimation { index += 1 }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(index >= category.words.count - 1)
            .accessibilityLabel("Next word")
            .accessibilityIdentifier("learn.next")
        }
        .font(.headline.weight(.bold))
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .padding(.horizontal, Spacing.l)
        .frame(maxWidth: 520)
    }

    private func autoplayCurrentWord() async {
        guard settings.autoplay, let word = currentWord else { return }
        // Let the swipe settle before speaking.
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled, practiceWord == nil else { return }
        speaker.play(word)
    }
}

/// One card: the picture on its stage, the word, syllables and an example sentence.
struct WordCardView: View {
    let word: Word
    let colors: [Color]
    let stars: Int

    @Environment(Speaker.self) private var speaker
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize: CGFloat = 52

    var body: some View {
        VStack(spacing: Spacing.s) {
            ZStack(alignment: .topTrailing) {
                StageBackground(colors: colors)
                WordVisualView(visual: word.visual)
                    .padding(Spacing.m)
                if stars > 0 {
                    StarsView(count: stars, size: 16, emptyColor: .white.opacity(0.6))
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xs)
                        .background(.black.opacity(0.18), in: Capsule())
                        .padding(Spacing.s)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: sizeClass == .regular ? 620 : 460)
            .softShadow()

            VStack(spacing: 0) {
                Text(verbatim: word.text)
                    .font(.system(size: wordSize, weight: .black, design: .rounded))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let syllables = word.syllables {
                    Text(verbatim: syllables)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.inkSecondary)
                        .accessibilityLabel(Text("Syllables: \(syllables)"))
                }
            }

            if let sentence = word.sentence {
                sentenceButton(sentence)
            }
        }
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sentenceButton(_ sentence: String) -> some View {
        Button {
            speaker.playSentence(of: word)
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(Color.brand)
                    .symbolEffect(.pulse, isActive: speaker.isPlaying(Speaker.sentenceTag(for: word)))
                Text(verbatim: sentence)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.callout.weight(.semibold))
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .background(Color.surface, in: Capsule())
            .softShadow()
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text(verbatim: sentence))
        .accessibilityHint("Plays the sentence")
        .accessibilityIdentifier("learn.sentence")
    }
}

#Preview {
    NavigationStack {
        LearnView(category: PreviewSupport.fruits, startIndex: 0)
    }
    .previewEnvironment()
}
