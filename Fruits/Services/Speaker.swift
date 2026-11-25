import AVFoundation
import Observation

/// Everything the app says out loud: words, sentences and little sound effects.
///
/// A word uses its human recording when one is bundled and the on-device voice otherwise,
/// so every word in the catalog is pronounced correctly, offline.
@MainActor
@Observable
final class Speaker: NSObject {
    enum Speed: Sendable { case normal, slow }

    enum Effect: String, CaseIterable, Sendable {
        case correct, retry, finish
    }

    /// Identifies what is playing right now, so the matching button can animate.
    private(set) var nowPlaying: String?

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let bundle: Bundle
    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var effectPlayers: [Effect: AVAudioPlayer] = [:]
    /// Held strongly so its identity can't be reused while it's the current utterance.
    @ObservationIgnored private var currentUtterance: AVSpeechUtterance?
    @ObservationIgnored private var voices: [AppSettings.Accent: AVSpeechSynthesisVoice] = [:]

    init(settings: AppSettings, bundle: Bundle = .main) {
        self.settings = settings
        self.bundle = bundle
        super.init()
        synthesizer.delegate = self
    }

    // MARK: Tags

    static func tag(for word: Word, speed: Speed) -> String {
        "\(word.id)#\(speed == .slow ? "slow" : "normal")"
    }

    static func sentenceTag(for word: Word) -> String { "\(word.id)#sentence" }

    func isPlaying(_ tag: String) -> Bool { nowPlaying == tag }

    // MARK: Playback

    func play(_ word: Word, speed: Speed = .normal) {
        stop()
        let tag = Self.tag(for: word, speed: speed)
        if speed == .normal, let file = word.audio, playRecording(named: file, tag: tag) { return }
        speak(word.text, tag: tag, speed: speed)
    }

    func playSentence(of word: Word) {
        guard let sentence = word.sentence else { return }
        stop()
        speak(sentence, tag: Self.sentenceTag(for: word), speed: .normal)
    }

    /// Says arbitrary text, e.g. a voice sample in Settings.
    func say(_ text: String, tag: String) {
        stop()
        speak(text, tag: tag, speed: .normal)
    }

    func stop() {
        player?.stop()
        player = nil
        currentUtterance = nil
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        nowPlaying = nil
    }

    func playEffect(_ effect: Effect) {
        if effectPlayers[effect] == nil {
            guard let url = bundle.url(forResource: effect.rawValue, withExtension: "wav") else {
                Log.audio.error("Missing sound effect \(effect.rawValue)")
                return
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = 0.7
                player.prepareToPlay()
                effectPlayers[effect] = player
            } catch {
                Log.audio.error("Couldn't load effect \(effect.rawValue): \(error.localizedDescription)")
                return
            }
        }
        guard let player = effectPlayers[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    // MARK: Private

    private func playRecording(named file: String, tag: String) -> Bool {
        let name = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            Log.audio.error("Recording \(file) is missing; using the voice instead")
            return false
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            guard player.play() else { return false }
            self.player = player
            nowPlaying = tag
            return true
        } catch {
            Log.audio.error("Couldn't play \(file): \(error.localizedDescription)")
            return false
        }
    }

    private func speak(_ text: String, tag: String, speed: Speed) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice(for: settings.accent)
        // A touch slower than the system default so young learners can follow.
        utterance.rate = speed == .slow ? 0.28 : 0.42
        currentUtterance = utterance
        nowPlaying = tag
        synthesizer.speak(utterance)
    }

    /// Prefers an enhanced or premium voice when the user has downloaded one.
    private func voice(for accent: AppSettings.Accent) -> AVSpeechSynthesisVoice? {
        if let cached = voices[accent] { return cached }
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language == accent.languageCode
                && !$0.voiceTraits.contains(.isNoveltyVoice)
                && !$0.voiceTraits.contains(.isPersonalVoice)
        }
        let best = candidates
            .filter { $0.quality != .default }
            .max { $0.quality.rawValue < $1.quality.rawValue }
        let voice = best ?? AVSpeechSynthesisVoice(language: accent.languageCode)
        voices[accent] = voice
        return voice
    }

    fileprivate func didFinishUtterance(_ id: ObjectIdentifier) {
        guard let currentUtterance, ObjectIdentifier(currentUtterance) == id else { return }
        self.currentUtterance = nil
        nowPlaying = nil
    }

    fileprivate func didFinishPlayer(_ id: ObjectIdentifier) {
        guard let player, ObjectIdentifier(player) == id else { return }
        self.player = nil
        nowPlaying = nil
    }
}

extension Speaker: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.didFinishUtterance(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.didFinishUtterance(id) }
    }
}

extension Speaker: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor in self.didFinishPlayer(id) }
    }
}
