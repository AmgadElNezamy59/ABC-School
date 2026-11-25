import Foundation
import Testing
@testable import Fruits

@MainActor
final class FakeRecorder: VoiceRecording {
    var permission: MicPermission = .granted
    var grantsPermission = true
    var startError: Error?
    var peakLevel: Float = 0.8
    var recording: URL? = URL(fileURLWithPath: "/tmp/practice-test.m4a")
    private(set) var startCount = 0
    private(set) var playCount = 0
    private(set) var discarded = false

    func requestPermission() async -> Bool {
        permission = grantsPermission ? .granted : .denied
        return grantsPermission
    }

    func start() throws {
        if let startError { throw startError }
        startCount += 1
    }

    func sampleLevel() -> Float { 0 }
    func stop() -> URL? { recording }

    @discardableResult
    func playRecording() -> Bool {
        playCount += 1
        return true
    }

    func discard() { discarded = true }
}

@MainActor
final class FakeChecker: SpeechChecking {
    var status: SpeechCheckStatus = .available
    var statusAfterRequest: SpeechCheckStatus = .available
    var transcripts: [String] = []
    var error: Error?
    private(set) var requestedAccess = false
    private(set) var lastHints: [String] = []

    func requestAccess() async -> SpeechCheckStatus {
        requestedAccess = true
        status = statusAfterRequest
        return status
    }

    func transcribe(_ url: URL, hints: [String]) async throws -> [String] {
        lastHints = hints
        if let error { throw error }
        return transcripts
    }
}

@MainActor
struct PracticeModelTests {
    let apple = Word(id: "fruits.apple", text: "Apple", syllables: "Ap·ple", sentence: nil,
                     visual: .photo("apple"), colors: nil, audio: nil, accepted: nil)

    private func makeModel(
        recorder: FakeRecorder = FakeRecorder(),
        checker: FakeChecker = FakeChecker()
    ) -> (PracticeModel, ProgressStore) {
        let progress = ProgressStore(defaults: makeDefaults())
        return (PracticeModel(word: apple, recorder: recorder, checker: checker, progress: progress), progress)
    }

    @Test func startPhaseFollowsMicrophonePermission() {
        let undetermined = FakeRecorder()
        undetermined.permission = .undetermined
        #expect(makeModel(recorder: undetermined).0.phase == .intro)

        let denied = FakeRecorder()
        denied.permission = .denied
        #expect(makeModel(recorder: denied).0.phase == .micDenied)

        #expect(makeModel().0.phase == .ready)
    }

    @Test func grantingPermissionAlsoAsksForSpeechRecognition() async {
        let recorder = FakeRecorder()
        recorder.permission = .undetermined
        let checker = FakeChecker()
        checker.status = .needsPermission
        let (model, _) = makeModel(recorder: recorder, checker: checker)

        await model.requestPermissions()
        #expect(model.phase == .ready)
        #expect(checker.requestedAccess)
    }

    @Test func decliningTheMicrophoneShowsHowToFixIt() async {
        let recorder = FakeRecorder()
        recorder.permission = .undetermined
        recorder.grantsPermission = false
        let (model, _) = makeModel(recorder: recorder)

        await model.requestPermissions()
        #expect(model.phase == .micDenied)
    }

    @Test func aClearAttemptEarnsThreeStarsAndIsSaved() async {
        let checker = FakeChecker()
        checker.transcripts = ["Apple"]
        let (model, progress) = makeModel(checker: checker)

        model.startRecording()
        #expect(model.phase == .recording)
        await model.stopRecording()

        #expect(model.phase == .result(.init(stars: 3, heard: "Apple")))
        #expect(model.hasRecording)
        #expect(progress.stars["fruits.apple"] == 3)
        #expect(checker.lastHints == ["Apple"])
    }

    @Test func aNearMissEarnsFewerStarsButNeverLowersTheBest() async {
        let checker = FakeChecker()
        checker.transcripts = ["Appel"]
        let (model, progress) = makeModel(checker: checker)
        progress.recordPractice(stars: 3, for: apple.id)

        model.startRecording()
        await model.stopRecording()

        guard case .result(let feedback) = model.phase else {
            Issue.record("Expected a result, got \(model.phase)")
            return
        }
        #expect(feedback.stars == 1)
        #expect(progress.stars["fruits.apple"] == 3)
    }

    @Test func zeroStarsAreShownButNotSaved() async {
        let checker = FakeChecker()
        checker.transcripts = ["elephant"]
        let (model, progress) = makeModel(checker: checker)

        model.startRecording()
        await model.stopRecording()

        #expect(model.phase == .result(.init(stars: 0, heard: "elephant")))
        #expect(progress.stars["fruits.apple"] == nil)
    }

    @Test func aSilentRecordingAsksTheChildToSpeakUp() async {
        let recorder = FakeRecorder()
        recorder.peakLevel = 0.05
        let (model, _) = makeModel(recorder: recorder)

        model.startRecording()
        await model.stopRecording()
        #expect(model.phase == .noSpeech)
    }

    @Test func aTooShortRecordingCountsAsSilence() async {
        let recorder = FakeRecorder()
        recorder.recording = nil
        let (model, _) = makeModel(recorder: recorder)

        model.startRecording()
        await model.stopRecording()
        #expect(model.phase == .noSpeech)
        #expect(!model.hasRecording)
    }

    @Test func withoutOnDeviceRecognitionAGrownUpConfirms() async {
        let checker = FakeChecker()
        checker.status = .unsupported
        let (model, progress) = makeModel(checker: checker)
        #expect(!model.checksAutomatically)

        model.startRecording()
        await model.stopRecording()
        #expect(model.phase == .selfCheck)

        model.playRecording()
        model.confirmSelfCheck()
        #expect(model.phase == .result(.init(stars: 3, heard: nil)))
        #expect(progress.stars["fruits.apple"] == 3)
    }

    @Test func recognitionErrorsFallBackToSelfCheck() async {
        let checker = FakeChecker()
        checker.error = URLError(.timedOut)
        let (model, _) = makeModel(checker: checker)

        model.startRecording()
        await model.stopRecording()
        #expect(model.phase == .selfCheck)
    }

    @Test func aMicrophoneFailureIsRecoverable() async {
        let recorder = FakeRecorder()
        recorder.startError = URLError(.unknown)
        let (model, _) = makeModel(recorder: recorder)

        model.startRecording()
        #expect(model.phase == .failed)
        #expect(model.canRecord)

        recorder.startError = nil
        model.startRecording()
        #expect(model.phase == .recording)
    }

    @Test func tryAgainAfterAResultRecordsAgain() async {
        let checker = FakeChecker()
        checker.transcripts = ["Apple"]
        let recorder = FakeRecorder()
        let (model, _) = makeModel(recorder: recorder, checker: checker)

        model.startRecording()
        await model.stopRecording()
        model.startRecording()
        #expect(model.phase == .recording)
        #expect(recorder.startCount == 2)
    }

    @Test func closingDiscardsTheRecording() {
        let recorder = FakeRecorder()
        let (model, _) = makeModel(recorder: recorder)
        model.startRecording()
        model.close()
        #expect(recorder.discarded)
    }

    @Test func cannotStartWhileAlreadyRecording() {
        let recorder = FakeRecorder()
        let (model, _) = makeModel(recorder: recorder)
        model.startRecording()
        model.startRecording()
        #expect(recorder.startCount == 1)
    }
}
