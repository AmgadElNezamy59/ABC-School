import AVFoundation

/// The app's audio session rules in one place.
enum AudioSession {
    /// Words must be audible even when the ring/silent switch is on:
    /// hearing the word *is* the lesson.
    static func useForPlayback() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            Log.audio.error("Couldn't set playback category: \(error.localizedDescription)")
        }
    }

    /// Used while practicing: record the child, then play both voices through the speaker.
    static func useForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)
    }
}
