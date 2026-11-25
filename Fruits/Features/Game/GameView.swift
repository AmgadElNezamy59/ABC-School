import SwiftUI

/// "Listen & Find": hear a word, tap its picture. Eight quick rounds per game.
struct GameView: View {
    let category: Category

    @Environment(ProgressStore.self) private var progress
    @State private var game: ListenGame?

    var body: some View {
        Group {
            if let game {
                GameContent(game: game)
            } else {
                Color.appBackground.ignoresSafeArea()
            }
        }
        .onAppear {
            if game == nil { game = ListenGame(category: category, progress: progress) }
        }
    }
}

private struct GameContent: View {
    let game: ListenGame

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(Speaker.self) private var speaker
    @State private var confirmsExit = false
    @State private var shakes: [Word.ID: Int] = [:]
    @State private var correctPicks = 0
    @State private var wrongPicks = 0

    private var hasProgress: Bool {
        game.roundIndex > 0 || game.isRoundSolved || !game.wrongPicks.isEmpty
    }

    var body: some View {
        VStack(spacing: Spacing.l) {
            topBar
            // A ZStack lets the outgoing and incoming rounds overlap while they animate.
            ZStack(alignment: .top) {
                if game.isFinished {
                    GameResultView(game: game) { dismiss() }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else if let round = game.currentRound {
                    roundView(round)
                        .id(round.id)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    ContentUnavailableView("Not enough words to play",
                                           systemImage: "gamecontroller",
                                           description: Text("This topic needs at least two words for a game."))
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(Spacing.m)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground.ignoresSafeArea())
        .task(id: game.isFinished ? -1 : game.roundIndex) { await speakCurrentRound() }
        .onChange(of: game.isFinished) { _, finished in
            if finished { speaker.playEffect(.finish) }
        }
        .onDisappear { speaker.stop() }
        .sensoryFeedback(.success, trigger: correctPicks)
        .sensoryFeedback(.impact(weight: .light), trigger: wrongPicks)
        .alert("Leave the game?", isPresented: $confirmsExit) {
            Button("Keep Playing", role: .cancel) {}
            Button("Leave Game", role: .destructive) { dismiss() }
        } message: {
            Text("This game's score won't be saved.")
        }
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack(spacing: Spacing.m) {
            Button {
                if game.isFinished || !hasProgress { dismiss() } else { confirmsExit = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .tint(.ink)
            .accessibilityLabel("Close game")
            .accessibilityIdentifier("game.close")

            if !game.isFinished {
                let completed = game.roundIndex + (game.isRoundSolved ? 1 : 0)
                ProgressBar(value: Double(completed) / Double(max(game.rounds.count, 1)), height: 12)
                Text("\(game.roundIndex + 1) / \(game.rounds.count)")
                    .font(.headline.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(Color.inkSecondary)
                    .accessibilityLabel(Text("Round \(game.roundIndex + 1) of \(game.rounds.count)"))
                    .accessibilityIdentifier("game.round")
            } else {
                Spacer()
            }
        }
    }

    private func roundView(_ round: GameRound) -> some View {
        VStack(spacing: Spacing.l) {
            Button {
                speaker.play(round.answer)
            } label: {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 40, weight: .bold))
                    .symbolEffect(.variableColor.iterative,
                                  isActive: speaker.isPlaying(Speaker.tag(for: round.answer, speed: .normal)))
                    .frame(width: 104, height: 104)
            }
            .buttonStyle(ChunkyButtonStyle(color: .brand, shape: .circle))
            .accessibilityLabel("Hear the word again")
            .accessibilityIdentifier("game.replay")

            Text("Find the picture you hear")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.m), GridItem(.flexible())], spacing: Spacing.m) {
                ForEach(round.options) { option in
                    optionTile(option, in: round)
                }
            }
        }
    }

    private func optionTile(_ option: Word, in round: GameRound) -> some View {
        let isWrong = game.wrongPicks.contains(option.id)
        let isAnswer = option.id == round.answer.id
        let isCorrect = isAnswer && game.isRoundSolved
        let isHinted = isAnswer && game.showsHint
        let border: Color = isCorrect ? .success : isWrong ? .attention : isHinted ? .star : .clear

        return Button {
            pick(option)
        } label: {
            ZStack {
                StageBackground(colors: (option.colors ?? game.category.colors).gradientColors)
                WordVisualView(visual: option.visual)
                    .padding(Spacing.s)
                if isCorrect || isWrong {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white, isCorrect ? Color.success : Color.attention)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(Spacing.xs)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                    .strokeBorder(border, lineWidth: 6)
            }
            .opacity(isWrong ? 0.5 : 1)
            .scaleEffect((isCorrect || isHinted) && !reduceMotion ? 1.05 : 1)
            .softShadow()
            .modifier(ShakeEffect(shakes: CGFloat(shakes[option.id] ?? 0)))
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isCorrect)
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isHinted)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isWrong || game.isRoundSolved)
        .accessibilityLabel(Text(verbatim: option.text))
        .accessibilityValue(isCorrect ? Text("Correct") : isWrong ? Text("Not this one") : Text(verbatim: ""))
        .accessibilityIdentifier("game.option.\(option.id)")
    }

    // MARK: Actions

    private func pick(_ option: Word) {
        switch game.pick(option) {
        case .correct:
            correctPicks += 1
            speaker.stop()
            speaker.playEffect(.correct)
            Task {
                try? await Task.sleep(for: .seconds(1.1))
                withAnimation(.snappy) { game.advance() }
            }
        case .wrong:
            wrongPicks += 1
            speaker.playEffect(.retry)
            withAnimation(reduceMotion ? nil : .linear(duration: 0.4)) {
                shakes[option.id, default: 0] += 1
            }
        case .ignored:
            break
        }
    }

    private func speakCurrentRound() async {
        guard !game.isFinished, let round = game.currentRound else { return }
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }
        speaker.play(round.answer)
    }
}

/// End-of-game celebration.
private struct GameResultView: View {
    let game: ListenGame
    let onDone: () -> Void

    @State private var celebrate = false

    private var title: LocalizedStringKey {
        switch game.stars {
        case 3: "Amazing!"
        case 2: "Well done!"
        default: "Good effort!"
        }
    }

    var body: some View {
        VStack(spacing: Spacing.l) {
            Spacer(minLength: 0)
            Image(systemName: game.stars == 3 ? "trophy.fill" : "star.circle.fill")
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(Color.star)
                .symbolEffect(.bounce, value: celebrate)
                .accessibilityHidden(true)
            Text(title)
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(Color.ink)
            StarsView(count: game.stars, size: 40)
            Text("\(game.firstTryCorrect) of \(game.rounds.count) right on the first try")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
            if game.isNewBest {
                Label("New best score!", systemImage: "sparkles")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.brand.opacity(0.12), in: Capsule())
            }
            Spacer(minLength: 0)
            VStack(spacing: Spacing.s) {
                Button {
                    withAnimation(.snappy) { game.restart() }
                } label: {
                    Label("Play Again", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(color: .success))
                .accessibilityIdentifier("game.playAgain")

                Button(action: onDone) {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(color: .surface, foreground: .ink))
                .accessibilityIdentifier("game.done")
            }
        }
        .onAppear { celebrate = true }
    }
}

/// Side-to-side wiggle for a wrong answer.
private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(shakes * .pi * 4), y: 0))
    }
}

#Preview {
    GameView(category: PreviewSupport.fruits)
        .previewEnvironment()
}
