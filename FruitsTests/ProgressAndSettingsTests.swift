import Foundation
import Testing
@testable import Fruits

/// A fresh, isolated UserDefaults for each test.
func makeDefaults() -> UserDefaults {
    let name = "tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name) ?? .standard
    defaults.removePersistentDomain(forName: name)
    return defaults
}

func makeCategory(id: String = "test", wordCount: Int) -> Fruits.Category {
    let words = (0..<wordCount).map { index in
        Word(id: "\(id).\(index)", text: "Word\(index)", syllables: nil, sentence: nil,
             visual: .emoji("⭐️"), colors: nil, audio: nil, accepted: nil)
    }
    return Fruits.Category(id: id, title: id.capitalized, cover: .emoji("⭐️"), colors: ["#000000", "#000000"], words: words)
}

@MainActor
struct ProgressStoreTests {
    @Test func startsEmpty() {
        let store = ProgressStore(defaults: makeDefaults())
        #expect(store.totalStars == 0)
        #expect(store.stars.isEmpty)
    }

    @Test func keepsTheBestStarsPerWord() {
        let store = ProgressStore(defaults: makeDefaults())
        store.recordPractice(stars: 2, for: "fruits.apple")
        store.recordPractice(stars: 1, for: "fruits.apple")
        #expect(store.stars["fruits.apple"] == 2)
        store.recordPractice(stars: 3, for: "fruits.apple")
        #expect(store.stars["fruits.apple"] == 3)
    }

    @Test func clampsStarsToTheValidRange() {
        let store = ProgressStore(defaults: makeDefaults())
        store.recordPractice(stars: 9, for: "a")
        store.recordPractice(stars: -2, for: "b")
        #expect(store.stars["a"] == 3)
        #expect(store.stars["b"] == nil)
    }

    @Test func countsPracticedWordsAndTotalStars() {
        let category = makeCategory(wordCount: 5)
        let store = ProgressStore(defaults: makeDefaults())
        store.recordPractice(stars: 3, for: category.words[0].id)
        store.recordPractice(stars: 1, for: category.words[2].id)
        store.recordPractice(stars: 2, for: "other.word")
        #expect(store.practicedCount(in: category) == 2)
        #expect(store.stars(for: category.words[2]) == 1)
        #expect(store.totalStars == 6)
    }

    @Test func survivesARelaunch() {
        let defaults = makeDefaults()
        let store = ProgressStore(defaults: defaults)
        store.recordPractice(stars: 2, for: "animals.cat")
        store.recordGame(correct: 6, total: 8, for: "animals")

        let reloaded = ProgressStore(defaults: defaults)
        #expect(reloaded.stars["animals.cat"] == 2)
        #expect(reloaded.bestGames["animals"] == .init(correct: 6, total: 8))
    }

    @Test func onlyBetterGamesReplaceTheBest() {
        let store = ProgressStore(defaults: makeDefaults())
        #expect(store.recordGame(correct: 5, total: 8, for: "fruits"))
        #expect(!store.recordGame(correct: 4, total: 8, for: "fruits"))
        #expect(!store.recordGame(correct: 5, total: 8, for: "fruits"))
        #expect(store.recordGame(correct: 7, total: 8, for: "fruits"))
        #expect(store.bestGames["fruits"] == .init(correct: 7, total: 8))
        #expect(!store.recordGame(correct: 1, total: 0, for: "fruits"))
    }

    @Test func resetClearsEverythingIncludingStorage() {
        let defaults = makeDefaults()
        let store = ProgressStore(defaults: defaults)
        store.recordPractice(stars: 3, for: "x")
        store.recordGame(correct: 8, total: 8, for: "y")
        store.reset()
        #expect(store.totalStars == 0)
        #expect(store.bestGames.isEmpty)
        #expect(ProgressStore(defaults: defaults).totalStars == 0)
    }

    @Test func corruptDataStartsFreshInsteadOfCrashing() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: "progress.v1")
        let store = ProgressStore(defaults: defaults)
        #expect(store.totalStars == 0)
        store.recordPractice(stars: 1, for: "a")
        #expect(ProgressStore(defaults: defaults).stars["a"] == 1)
    }
}

@MainActor
struct AppSettingsTests {
    @Test func defaultsToAmericanEnglishWithAutoplay() {
        let settings = AppSettings(defaults: makeDefaults())
        #expect(settings.accent == .american)
        #expect(settings.autoplay)
    }

    @Test func persistsChanges() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.accent = .british
        settings.autoplay = false

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.accent == .british)
        #expect(!reloaded.autoplay)
    }

    @Test func ignoresUnknownStoredValues() {
        let defaults = makeDefaults()
        defaults.set("fr-FR", forKey: "settings.accent")
        #expect(AppSettings(defaults: defaults).accent == .american)
    }
}

struct HexColorTests {
    @Test func parsesWithOrWithoutHash() throws {
        let red = try #require(HexColor("#FF0000"))
        #expect(red == HexColor(red: 1, green: 0, blue: 0))
        #expect(HexColor("00ff00") == HexColor(red: 0, green: 1, blue: 0))
    }

    @Test func rejectsMalformedValues() {
        #expect(HexColor("#FFF") == nil)
        #expect(HexColor("#GG0000") == nil)
        #expect(HexColor("") == nil)
    }

    @Test func computesWCAGContrast() throws {
        let black = try #require(HexColor("#000000"))
        #expect(abs(black.contrast(with: .white) - 21) < 0.01)
        #expect(abs(HexColor.white.contrast(with: .white) - 1) < 0.01)
    }
}
