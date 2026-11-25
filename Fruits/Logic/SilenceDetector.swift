import Foundation

/// Decides when to stop recording so a child never has to tap "stop":
/// recording ends shortly after they finish speaking, or after a hard time limit.
struct SilenceDetector: Sendable {
    /// Normalized input level (0–1) that counts as speech. About -32 dB.
    static let speechThreshold: Float = 0.35

    var silenceToStop: TimeInterval = 0.9
    var maxDuration: TimeInterval = 5

    private(set) var heardSpeech = false
    private var silenceStartedAt: TimeInterval?

    /// Feed the latest level; returns `true` when recording should stop.
    mutating func shouldStop(level: Float, at elapsed: TimeInterval) -> Bool {
        if elapsed >= maxDuration { return true }
        if level >= Self.speechThreshold {
            heardSpeech = true
            silenceStartedAt = nil
            return false
        }
        guard heardSpeech else { return false }
        guard let silenceStartedAt else {
            self.silenceStartedAt = elapsed
            return false
        }
        return elapsed - silenceStartedAt >= silenceToStop
    }
}
