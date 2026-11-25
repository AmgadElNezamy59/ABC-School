import Testing
@testable import Fruits

struct GameBuilderTests {
    @Test func buildsEightRoundsWithUniqueAnswers() {
        var generator = SeededGenerator(seed: 1)
        let rounds = GameBuilder.makeRounds(from: makeCategory(wordCount: 12).words, using: &generator)
        #expect(rounds.count == 8)
        #expect(Set(rounds.map(\.answer.id)).count == 8)
        #expect(rounds.map(\.id) == Array(0..<8))
    }

    @Test func everyRoundHasFourDistinctOptionsIncludingTheAnswer() {
        var generator = SeededGenerator(seed: 2)
        for round in GameBuilder.makeRounds(from: makeCategory(wordCount: 12).words, using: &generator) {
            #expect(round.options.count == 4)
            #expect(Set(round.options.map(\.id)).count == 4)
            #expect(round.options.contains(round.answer))
        }
    }

    @Test func smallTopicsGetFewerRoundsAndOptions() {
        var generator = SeededGenerator(seed: 3)
        let rounds = GameBuilder.makeRounds(from: makeCategory(wordCount: 3).words, using: &generator)
        #expect(rounds.count == 3)
        #expect(rounds.allSatisfy { $0.options.count == 3 })
    }

    @Test func needsAtLeastTwoDistinctWords() {
        var generator = SeededGenerator(seed: 4)
        let one = makeCategory(wordCount: 1).words
        #expect(GameBuilder.makeRounds(from: one, using: &generator).isEmpty)
        #expect(GameBuilder.makeRounds(from: one + one, using: &generator).isEmpty)
    }

    @Test func sameSeedGivesTheSameGame() {
        let words = makeCategory(wordCount: 12).words
        var first = SeededGenerator(seed: 42)
        var second = SeededGenerator(seed: 42)
        #expect(GameBuilder.makeRounds(from: words, using: &first) == GameBuilder.makeRounds(from: words, using: &second))
    }

    @Test(arguments: [(8, 8, 3), (7, 8, 3), (6, 8, 2), (4, 8, 2), (3, 8, 1), (0, 8, 1), (0, 0, 0)])
    func stars(firstTry: Int, total: Int, expected: Int) {
        #expect(GameBuilder.stars(firstTryCorrect: firstTry, total: total) == expected)
    }
}

@MainActor
struct ListenGameTests {
    private func makeGame(seed: UInt64 = 7) -> (ListenGame, ProgressStore) {
        let progress = ProgressStore(defaults: makeDefaults())
        return (ListenGame(category: makeCategory(id: "fruits", wordCount: 12), progress: progress, seed: seed), progress)
    }

    private func wrongOption(in game: ListenGame) throws -> Word {
        let round = try #require(game.currentRound)
        return try #require(round.options.first { $0.id != round.answer.id })
    }

    @Test func correctFirstPickScores() throws {
        let (game, _) = makeGame()
        let answer = try #require(game.currentRound?.answer)
        #expect(game.pick(answer) == .correct)
        #expect(game.isRoundSolved)
        #expect(game.firstTryCorrect == 1)
    }

    @Test func wrongPicksLockThatOptionAndCostTheFirstTryPoint() throws {
        let (game, _) = makeGame()
        let wrong = try wrongOption(in: game)
        #expect(game.pick(wrong) == .wrong)
        #expect(game.pick(wrong) == .ignored)
        #expect(game.wrongPicks == [wrong.id])

        let answer = try #require(game.currentRound?.answer)
        #expect(game.pick(answer) == .correct)
        #expect(game.firstTryCorrect == 0)
    }

    @Test func showsAHintAfterTwoMisses() throws {
        let (game, _) = makeGame()
        let round = try #require(game.currentRound)
        let wrongs = round.options.filter { $0.id != round.answer.id }
        _ = game.pick(wrongs[0])
        #expect(!game.showsHint)
        _ = game.pick(wrongs[1])
        #expect(game.showsHint)
        _ = game.pick(round.answer)
        #expect(!game.showsHint)
    }

    @Test func cannotAdvanceBeforeSolvingTheRound() {
        let (game, _) = makeGame()
        game.advance()
        #expect(game.roundIndex == 0)
    }

    @Test func playingEveryRoundFinishesAndSavesTheBestScore() throws {
        let (game, progress) = makeGame()
        for index in 0..<game.rounds.count {
            let round = try #require(game.currentRound)
            if index == 0 {
                let wrong = try wrongOption(in: game)
                #expect(game.pick(wrong) == .wrong)
            }
            #expect(game.pick(round.answer) == .correct)
            game.advance()
        }
        #expect(game.isFinished)
        #expect(game.firstTryCorrect == 7)
        #expect(game.stars == 3)
        #expect(game.isNewBest)
        #expect(progress.bestGames["fruits"] == .init(correct: 7, total: 8))
        #expect(game.pick(game.rounds[0].answer) == .ignored)
    }

    @Test func restartBeginsAFreshGame() throws {
        let (game, _) = makeGame()
        let answer = try #require(game.currentRound?.answer)
        _ = game.pick(answer)
        game.advance()
        game.restart()
        #expect(game.roundIndex == 0)
        #expect(game.firstTryCorrect == 0)
        #expect(!game.isRoundSolved)
        #expect(!game.isFinished)
        #expect(game.rounds.count == 8)
    }
}
