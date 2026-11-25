import AVFoundation

enum MicPermission: Sendable {
    case undetermined, denied, granted
}

/// Records the child's attempt. A protocol so practice logic can be tested without a microphone.
@MainActor
protocol VoiceRecording: AnyObject {
    var permission: MicPermission { get }
    func requestPermission() async -> Bool
    func start() throws
    /// Current input level from 0 (silence) to 1 (loud). Also updates `peakLevel`.
    func sampleLevel() -> Float
    /// Loudest level seen since `start()`.
    var peakLevel: Float { get }
    /// Stops recording and returns the file, or `nil` if nothing usable was recorded.
    func stop() -> URL?
    @discardableResult func playRecording() -> Bool
    /// Stops everything and deletes the recording.
    func discard()
}

@MainActor
final class VoiceRecorder: VoiceRecording {
    enum RecorderError: Error { case couldNotStart }

    private(set) var peakLevel: Float = 0
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    /// One reusable file in tmp/; it's deleted when practice ends.
    private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("practice.m4a")

    var permission: MicPermission {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: .granted
        case .denied: .denied
        default: .undetermined
        }
    }

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func start() throws {
        player?.stop()
        player = nil
        try AudioSession.useForRecording()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.isMeteringEnabled = true
        guard recorder.record() else { throw RecorderError.couldNotStart }
        self.recorder = recorder
        peakLevel = 0
    }

    func sampleLevel() -> Float {
        guard let recorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        // averagePower is in dB (-160…0); map the useful -50…0 range to 0…1.
        let level = max(0, min(1, (recorder.averagePower(forChannel: 0) + 50) / 50))
        peakLevel = max(peakLevel, level)
        return level
    }

    func stop() -> URL? {
        guard let recorder else { return nil }
        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        return duration > 0.2 ? fileURL : nil
    }

    @discardableResult
    func playRecording() -> Bool {
        guard recorder == nil, FileManager.default.fileExists(atPath: fileURL.path) else { return false }
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            self.player = player
            return player.play()
        } catch {
            Log.audio.error("Couldn't play the recording: \(error.localizedDescription)")
            return false
        }
    }

    func discard() {
        recorder?.stop()
        recorder = nil
        player?.stop()
        player = nil
        try? FileManager.default.removeItem(at: fileURL)
        AudioSession.useForPlayback()
    }
}
