import Foundation
import Observation

/// The "Say it" flow: permission → record → check → feedback.
@MainActor
@Observable
final class PracticeModel {
    enum Phase: Equatable {
        /// The microphone hasn't been requested yet.
        case intro
        case micDenied
        case ready
        case recording
        case checking
        case result(Feedback)
        /// Recorded, but no automatic check is possible: a grown-up listens and decides.
        case selfCheck
        /// The recording was silent.
        case noSpeech
        /// The microphone couldn't start.
        case failed
    }

    struct Feedback: Equatable {
        let stars: Int
        /// What speech recognition heard; `nil` when a grown-up confirmed the attempt.
        let heard: String?
    }

    let word: Word
    private(set) var phase: Phase
    /// Live input level for the recording animation, 0…1.
    private(set) var level: Float = 0
    /// Whether there is a recording the child can listen back to.
    private(set) var hasRecording = false

    @ObservationIgnored private let recorder: VoiceRecording
    @ObservationIgnored private let checker: SpeechChecking
    @ObservationIgnored private let progress: ProgressStore
    @ObservationIgnored private var monitorTask: Task<Void, Never>?
    @ObservationIgnored private var isClosed = false

    init(word: Word, recorder: VoiceRecording, checker: SpeechChecking, progress: ProgressStore) {
        self.word = word
        self.recorder = recorder
        self.checker = checker
        self.progress = progress
        phase = switch recorder.permission {
        case .granted: .ready
        case .denied: .micDenied
        case .undetermined: .intro
        }
    }

    /// `true` when attempts are checked automatically; `false` means record-and-compare.
    var checksAutomatically: Bool { checker.status == .available }

    var canRecord: Bool {
        switch phase {
        case .ready, .result, .selfCheck, .noSpeech, .failed: true
        default: false
        }
    }

    // MARK: Actions

    func requestPermissions() async {
        guard await recorder.requestPermission() else {
            phase = .micDenied
            return
        }
        if checker.status == .needsPermission {
            _ = await checker.requestAccess()
        }
        phase = .ready
    }

    func startRecording() {
        guard canRecord else { return }
        do {
            try recorder.start()
        } catch {
            Log.audio.error("Recording failed to start: \(error.localizedDescription)")
            phase = .failed
            return
        }
        hasRecording = false
        level = 0
        phase = .recording
        monitorTask = Task { [weak self] in await self?.monitorInput() }
    }

    /// Stops a recording the child ended by tapping.
    func stopRecording() async {
        guard phase == .recording else { return }
        monitorTask?.cancel()
        monitorTask = nil
        await finishRecording()
    }

    func playRecording() {
        recorder.playRecording()
    }

    /// A grown-up listened and confirmed the child said the word.
    func confirmSelfCheck() {
        guard phase == .selfCheck else { return }
        complete(with: Feedback(stars: ProgressStore.maxStars, heard: nil))
    }

    /// Ends practice: stops audio and deletes the recording.
    func close() {
        isClosed = true
        monitorTask?.cancel()
        monitorTask = nil
        recorder.discard()
    }

    // MARK: Private

    /// Polls the input level and stops once the child has finished speaking.
    private func monitorInput() async {
        let clock = ContinuousClock()
        let start = clock.now
        var detector = SilenceDetector()
        while phase == .recording {
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled, phase == .recording else { return }
            level = recorder.sampleLevel()
            let elapsed = start.duration(to: clock.now)
            let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
            if detector.shouldStop(level: level, at: seconds) { break }
        }
        guard !Task.isCancelled else { return }
        await finishRecording()
    }

    private func finishRecording() async {
        guard phase == .recording else { return }
        level = 0
        let heardSomething = recorder.peakLevel >= SilenceDetector.speechThreshold
        guard let url = recorder.stop() else {
            phase = .noSpeech
            return
        }
        hasRecording = true
        guard heardSomething else {
            phase = .noSpeech
            return
        }
        guard checker.status == .available else {
            phase = .selfCheck
            return
        }

        phase = .checking
        do {
            let candidates = try await checker.transcribe(url, hints: word.answers)
            guard !isClosed else { return }
            let score = PronunciationScorer.score(candidates: candidates, answers: word.answers)
            complete(with: Feedback(stars: score.stars, heard: score.heard ?? candidates.first))
        } catch {
            guard !isClosed else { return }
            // Recognition can fail on very short or unclear audio; let a grown-up judge instead.
            Log.speech.notice("Recognition failed, falling back to self-check: \(error.localizedDescription)")
            phase = .selfCheck
        }
    }

    private func complete(with feedback: Feedback) {
        if feedback.stars > 0 {
            progress.recordPractice(stars: feedback.stars, for: word.id)
        }
        phase = .result(feedback)
    }
}
