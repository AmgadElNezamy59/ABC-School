import Foundation
import Observation

/// "Listen & Find": hear a word, tap its picture. Rules only; the view handles sound and timing.
@MainActor
@Observable
final class ListenGame {
    enum Pick: Equatable { case correct, wrong, ignored }

    let category: Category
    private(set) var rounds: [GameRound] = []
    private(set) var roundIndex = 0
    private(set) var firstTryCorrect = 0
    /// Options already tried and wrong in the current round.
    private(set) var wrongPicks: Set<Word.ID> = []
    private(set) var isRoundSolved = false
    private(set) var isFinished = false
    private(set) var isNewBest = false

    @ObservationIgnored private let progress: ProgressStore
    @ObservationIgnored private var generator: SeededGenerator

    init(category: Category, progress: ProgressStore, seed: UInt64 = .random(in: 0...UInt64.max)) {
        self.category = category
        self.progress = progress
        generator = SeededGenerator(seed: seed)
        rounds = GameBuilder.makeRounds(from: category.words, using: &generator)
    }

    var currentRound: GameRound? {
        rounds.indices.contains(roundIndex) ? rounds[roundIndex] : nil
    }

    var stars: Int { GameBuilder.stars(firstTryCorrect: firstTryCorrect, total: rounds.count) }

    /// After two misses the right answer is highlighted, so nobody gets stuck.
    var showsHint: Bool { wrongPicks.count >= 2 && !isRoundSolved }

    func pick(_ word: Word) -> Pick {
        guard let round = currentRound, !isRoundSolved, !isFinished, !wrongPicks.contains(word.id) else {
            return .ignored
        }
        guard word.id == round.answer.id else {
            wrongPicks.insert(word.id)
            return .wrong
        }
        isRoundSolved = true
        if wrongPicks.isEmpty { firstTryCorrect += 1 }
        return .correct
    }

    /// Moves on after a solved round, finishing the game after the last one.
    func advance() {
        guard isRoundSolved, !isFinished else { return }
        if roundIndex + 1 < rounds.count {
            roundIndex += 1
            wrongPicks = []
            isRoundSolved = false
        } else {
            isFinished = true
            isNewBest = progress.recordGame(correct: firstTryCorrect, total: rounds.count, for: category.id)
        }
    }

    func restart() {
        rounds = GameBuilder.makeRounds(from: category.words, using: &generator)
        roundIndex = 0
        firstTryCorrect = 0
        wrongPicks = []
        isRoundSolved = false
        isFinished = false
        isNewBest = false
    }
}
