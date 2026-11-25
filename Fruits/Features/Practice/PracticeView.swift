import SwiftUI

/// "Say it": the child repeats the word and gets friendly feedback.
struct PracticeView: View {
    let word: Word
    let colors: [Color]

    @Environment(ProgressStore.self) private var progress
    @Environment(AppSettings.self) private var settings
    @State private var model: PracticeModel?

    var body: some View {
        Group {
            if let model {
                PracticeContent(model: model, colors: colors)
            } else {
                Color.appBackground.ignoresSafeArea()
            }
        }
        .onAppear {
            guard model == nil else { return }
            model = PracticeModel(word: word,
                                  recorder: VoiceRecorder(),
                                  checker: SpeechChecker(languageCode: settings.accent.languageCode),
                                  progress: progress)
        }
    }
}

private struct PracticeContent: View {
    let model: PracticeModel
    let colors: [Color]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(Speaker.self) private var speaker

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                wordHeader
                Spacer(minLength: 0)
                phaseContent
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                Spacer(minLength: 0)
            }
            .padding(Spacing.m)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
            .animation(.snappy, value: model.phase)
            .navigationTitle("Say It")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("practice.done")
                }
            }
        }
        .onAppear {
            if model.phase == .ready { speaker.play(model.word) }
        }
        .onDisappear {
            speaker.stop()
            model.close()
        }
        .onChange(of: model.phase) { _, phase in
            switch phase {
            case .result(let feedback): speaker.playEffect(feedback.stars >= 2 ? .correct : .retry)
            case .noSpeech: speaker.playEffect(.retry)
            default: break
            }
        }
        .sensoryFeedback(trigger: model.phase) { _, phase in
            switch phase {
            case .result(let feedback): feedback.stars >= 2 ? .success : .warning
            case .recording: .impact(weight: .medium)
            default: nil
            }
        }
    }

    // MARK: Pieces

    private var wordHeader: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                StageBackground(colors: colors, cornerRadius: Radius.medium)
                WordVisualView(visual: model.word.visual).padding(Spacing.xxs)
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Say this word")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.inkSecondary)
                Text(verbatim: model.word.text)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer(minLength: 0)
            Button {
                speaker.play(model.word)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2.weight(.bold))
                    .symbolEffect(.variableColor.iterative, isActive: speaker.isPlaying(Speaker.tag(for: model.word, speed: .normal)))
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(ChunkyButtonStyle(color: .brand, shape: .circle))
            .disabled(model.phase == .recording)
            .accessibilityLabel("Hear the word")
        }
        .padding(Spacing.s)
        .surfaceCard()
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch model.phase {
        case .intro:
            MessageBlock(systemImage: "mic.circle.fill", tint: .brand,
                         title: "Practice saying words",
                         message: "Your child hears a word, then says it back. The microphone is only used while recording, and recordings are deleted right away.") {
                Button("Turn On Microphone") {
                    Task {
                        await model.requestPermissions()
                        if model.phase == .ready { speaker.play(model.word) }
                    }
                }
                .buttonStyle(ChunkyButtonStyle())
                .accessibilityIdentifier("practice.allowMic")
            }

        case .micDenied:
            MessageBlock(systemImage: "mic.slash.circle.fill", tint: .attention,
                         title: "The microphone is off",
                         message: "To practice saying words, allow microphone access for ABC School in Settings.") {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .buttonStyle(ChunkyButtonStyle())
            }

        case .ready, .recording:
            VStack(spacing: Spacing.l) {
                MicButton(isRecording: model.phase == .recording, level: model.level) {
                    if model.phase == .recording {
                        Task { await model.stopRecording() }
                    } else {
                        speaker.stop()
                        model.startRecording()
                    }
                }
                Text(model.phase == .recording ? "Listening… say “\(model.word.text)”" : "Tap the microphone and say “\(model.word.text)”")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                if !model.checksAutomatically && model.phase == .ready {
                    Text("A grown-up will listen and compare.")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkSecondary)
                }
            }

        case .checking:
            VStack(spacing: Spacing.m) {
                ProgressView().controlSize(.large)
                Text("Checking…")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.ink)
            }
            .frame(minHeight: 200)

        case .result(let feedback):
            VStack(spacing: Spacing.l) {
                ResultBlock(feedback: feedback)
                compareButtons
                retryButton(primary: feedback.stars < 2)
            }

        case .selfCheck:
            VStack(spacing: Spacing.l) {
                MessageBlock(systemImage: "ear.fill", tint: .brand,
                             title: "Listen and compare",
                             message: "Play your child's voice, then the word. Did they sound the same?") {
                    EmptyView()
                }
                compareButtons
                HStack(spacing: Spacing.s) {
                    Button {
                        speaker.stop()
                        model.startRecording()
                    } label: {
                        Label("Try Again", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ChunkyButtonStyle(color: .surface, foreground: .ink))
                    Button {
                        model.confirmSelfCheck()
                    } label: {
                        Label("Sounds Right", systemImage: "hand.thumbsup.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ChunkyButtonStyle(color: .success))
                    .accessibilityIdentifier("practice.confirm")
                }
            }

        case .noSpeech:
            MessageBlock(systemImage: "ear.trianglebadge.exclamationmark", tint: .attention,
                         title: "I couldn't hear you",
                         message: "Hold the device a little closer and speak up.") {
                retryButton(primary: true)
            }

        case .failed:
            MessageBlock(systemImage: "exclamationmark.triangle.fill", tint: .attention,
                         title: "The microphone didn't start",
                         message: "Please try again. If it keeps happening, close the app and open it again.") {
                retryButton(primary: true)
            }
        }
    }

    private var compareButtons: some View {
        HStack(spacing: Spacing.s) {
            Button {
                speaker.stop()
                model.playRecording()
            } label: {
                Label("My Voice", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!model.hasRecording)
            Button {
                speaker.play(model.word)
            } label: {
                Label("The Word", systemImage: "speaker.wave.2.fill")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(ChunkyButtonStyle(color: .surface, foreground: .brand))
    }

    private func retryButton(primary: Bool) -> some View {
        Button {
            speaker.stop()
            model.startRecording()
        } label: {
            Label("Try Again", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(color: primary ? .brand : .surface, foreground: primary ? .white : .ink))
        .accessibilityIdentifier("practice.tryAgain")
    }
}

/// The big round record button with a ring that follows the child's voice.
private struct MicButton: View {
    let isRecording: Bool
    let level: Float
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill((isRecording ? Color.attention : Color.brand).opacity(0.18))
                    .scaleEffect(isRecording && !reduceMotion ? 1 + CGFloat(level) * 0.4 : 1)
                Circle()
                    .fill(isRecording ? Color.attention : Color.brand)
                    .padding(22)
                    .softShadow()
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 176, height: 176)
            .animation(.easeOut(duration: 0.12), value: level)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityIdentifier("practice.mic")
    }
}

/// Stars and a kind message after an automatic check.
private struct ResultBlock: View {
    let feedback: PracticeModel.Feedback

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var title: LocalizedStringKey {
        switch feedback.stars {
        case 3: "Perfect!"
        case 2: "Great job!"
        case 1: "Good try!"
        default: "Let's try again"
        }
    }

    var body: some View {
        VStack(spacing: Spacing.s) {
            StarsView(count: feedback.stars, size: 44)
                .scaleEffect(appeared || reduceMotion ? 1 : 0.4)
                .opacity(appeared || reduceMotion ? 1 : 0)
            Text(title)
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(Color.ink)
            if let heard = feedback.heard, !heard.isEmpty {
                Text("I heard “\(heard)”")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
            } else if feedback.stars == 0 {
                Text("Listen to the word, then say it slowly.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { appeared = true }
        }
    }
}

/// Icon, title, message and an optional action: used for every non-recording state.
private struct MessageBlock<Actions: View>: View {
    let systemImage: String
    let tint: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            actions()
        }
    }
}

#Preview {
    Text(verbatim: "Card")
        .sheet(isPresented: .constant(true)) {
            PracticeView(word: PreviewSupport.fruits.words[0], colors: ["#DB4636", "#550C09"].gradientColors)
        }
        .previewEnvironment()
}
