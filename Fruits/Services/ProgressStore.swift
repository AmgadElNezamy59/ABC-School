import Foundation
import Observation
import os

/// Remembers the best stars per word and the best game score per topic.
/// The whole snapshot is a few KB, so it lives in UserDefaults.
@MainActor
@Observable
final class ProgressStore {
    struct GameScore: Codable, Equatable, Sendable {
        var correct: Int
        var total: Int

        var ratio: Double { total > 0 ? Double(correct) / Double(total) : 0 }
    }

    private struct Snapshot: Codable {
        var version = 1
        var stars: [String: Int] = [:]
        var bestGames: [String: GameScore] = [:]
    }

    static let maxStars = 3
    private static let storageKey = "progress.v1"

    private(set) var stars: [String: Int]
    private(set) var bestGames: [String: GameScore]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var snapshot = Snapshot()
        if let data = defaults.data(forKey: Self.storageKey) {
            do {
                snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
            } catch {
                Log.storage.error("Saved progress was unreadable, starting fresh: \(error.localizedDescription)")
            }
        }
        stars = snapshot.stars
        bestGames = snapshot.bestGames
    }

    // MARK: Reading

    func stars(for word: Word) -> Int { stars[word.id] ?? 0 }

    /// Words with at least one star.
    func practicedCount(in category: Category) -> Int {
        category.words.filter { stars(for: $0) > 0 }.count
    }

    var totalStars: Int { stars.values.reduce(0, +) }

    func bestGame(for category: Category) -> GameScore? { bestGames[category.id] }

    // MARK: Writing

    /// Keeps the best result; a weaker attempt never lowers a word's stars.
    func recordPractice(stars newStars: Int, for wordID: Word.ID) {
        let clamped = min(max(newStars, 0), Self.maxStars)
        guard clamped > (stars[wordID] ?? 0) else { return }
        stars[wordID] = clamped
        save()
    }

    /// Saves the game if it beats the previous best. Returns `true` for a new best.
    @discardableResult
    func recordGame(correct: Int, total: Int, for categoryID: Category.ID) -> Bool {
        guard total > 0 else { return false }
        let score = GameScore(correct: min(max(correct, 0), total), total: total)
        if let previous = bestGames[categoryID], previous.ratio >= score.ratio { return false }
        bestGames[categoryID] = score
        save()
        return true
    }

    func reset() {
        stars = [:]
        bestGames = [:]
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(Snapshot(stars: stars, bestGames: bestGames))
            defaults.set(data, forKey: Self.storageKey)
        } catch {
            Log.storage.error("Couldn't save progress: \(error.localizedDescription)")
        }
    }
}
