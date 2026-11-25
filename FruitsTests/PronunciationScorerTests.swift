import Foundation
import Testing
@testable import Fruits

struct PronunciationScorerTests {
    @Test func exactMatchEarnsThreeStars() {
        let score = PronunciationScorer.score(candidates: ["Apple"], answers: ["Apple"])
        #expect(score == .init(stars: 3, heard: "Apple"))
    }

    @Test func ignoresCasePunctuationAndAccents() {
        #expect(PronunciationScorer.score(candidates: ["  APPLE!! "], answers: ["Apple"]).stars == 3)
        #expect(PronunciationScorer.score(candidates: ["Ápple."], answers: ["Apple"]).stars == 3)
    }

    @Test func findsTheWordInsideAPhrase() {
        #expect(PronunciationScorer.score(candidates: ["it's an apple"], answers: ["Apple"]).stars == 3)
    }

    @Test func matchesMultiWordAnswers() {
        let answers = ["W", "double you", "double u"]
        #expect(PronunciationScorer.score(candidates: ["Double you"], answers: answers).stars == 3)
        #expect(PronunciationScorer.score(candidates: ["yo-yo"], answers: ["Yo-yo"]).stars == 3)
    }

    @Test func acceptsAlternativeSpellings() {
        #expect(PronunciationScorer.score(candidates: ["Bee"], answers: ["B", "bee", "be"]).stars == 3)
        #expect(PronunciationScorer.score(candidates: ["7"], answers: ["Seven", "7"]).stars == 3)
    }

    @Test func nearMissesEarnPartialCredit() {
        // "banan" vs "banana": one letter off out of six.
        #expect(PronunciationScorer.score(candidates: ["banan"], answers: ["Banana"]).stars == 2)
        // "cap" vs "cat": one letter off out of three.
        #expect(PronunciationScorer.score(candidates: ["cap"], answers: ["Cat"]).stars == 1)
    }

    @Test func unrelatedWordsEarnNothing() {
        let score = PronunciationScorer.score(candidates: ["elephant"], answers: ["Cat"])
        #expect(score == .init(stars: 0, heard: nil))
    }

    @Test func onlyTheTopGuessCanBePerfect() {
        let score = PronunciationScorer.score(candidates: ["hello", "apple"], answers: ["Apple"])
        #expect(score == .init(stars: 2, heard: "apple"))
    }

    @Test func emptyInputIsSafe() {
        #expect(PronunciationScorer.score(candidates: [], answers: ["Apple"]).stars == 0)
        #expect(PronunciationScorer.score(candidates: [""], answers: ["Apple"]).stars == 0)
        #expect(PronunciationScorer.score(candidates: ["apple"], answers: []).stars == 0)
    }

    @Test(arguments: [(1.0, 3), (0.8, 2), (0.75, 2), (0.6, 1), (0.5, 1), (0.49, 0), (0, 0)])
    func starThresholds(similarity: Double, stars: Int) {
        #expect(PronunciationScorer.stars(for: similarity) == stars)
    }

    @Test func normalizesWhitespaceAndSymbols() {
        #expect(PronunciationScorer.normalize("  Ice-cream,  please! ") == "ice cream please")
    }
}

struct SilenceDetectorTests {
    /// Feeds (level, time) samples in order and returns each stop decision.
    private func decisions(_ samples: [(Float, TimeInterval)], detector: inout SilenceDetector) -> [Bool] {
        samples.map { detector.shouldStop(level: $0.0, at: $0.1) }
    }

    @Test func keepsRecordingWhileWaitingForSpeech() {
        var detector = SilenceDetector()
        let stops = decisions([(0.1, 0.5), (0.1, 2.5)], detector: &detector)
        #expect(stops == [false, false])
        #expect(!detector.heardSpeech)
    }

    @Test func stopsShortlyAfterTheChildFinishesSpeaking() {
        var detector = SilenceDetector()
        let stops = decisions([(0.8, 0.5), (0.1, 0.6), (0.1, 1.2), (0.1, 1.6)], detector: &detector)
        #expect(stops == [false, false, false, true])
        #expect(detector.heardSpeech)
    }

    @Test func aPauseBetweenSyllablesDoesNotStopRecording() {
        var detector = SilenceDetector()
        let stops = decisions([(0.8, 0.3), (0.1, 0.6), (0.7, 1.2), (0.1, 1.5), (0.1, 2.3), (0.1, 2.5)], detector: &detector)
        #expect(stops == [false, false, false, false, false, true])
    }

    @Test func alwaysStopsAtTheTimeLimit() {
        var detector = SilenceDetector()
        let stops = decisions([(0.9, 5)], detector: &detector)
        #expect(stops == [true])
    }
}
