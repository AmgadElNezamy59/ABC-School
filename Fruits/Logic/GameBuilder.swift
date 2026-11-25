import Foundation

/// One "Listen & Find" round: hear `answer`, pick it from `options`.
struct GameRound: Identifiable, Equatable, Sendable {
    let id: Int
    let answer: Word
    let options: [Word]
}

enum GameBuilder {
    static let roundsPerGame = 8
    static let optionsPerRound = 4

    /// Builds rounds with unique answers and distinct options, in random order.
    static func makeRounds<G: RandomNumberGenerator>(
        from words: [Word],
        count: Int = roundsPerGame,
        optionsPerRound: Int = optionsPerRound,
        using generator: inout G
    ) -> [GameRound] {
        var seen = Set<Word.ID>()
        let unique = words.filter { seen.insert($0.id).inserted }
        guard unique.count >= 2, count > 0 else { return [] }

        let optionCount = min(optionsPerRound, unique.count)
        let answers = unique.shuffled(using: &generator).prefix(count)
        return answers.enumerated().map { index, answer in
            let distractors = unique.filter { $0.id != answer.id }
                .shuffled(using: &generator)
                .prefix(optionCount - 1)
            let options = ([answer] + distractors).shuffled(using: &generator)
            return GameRound(id: index, answer: answer, options: options)
        }
    }

    /// Stars for a finished game. Finishing always earns at least one star.
    static func stars(firstTryCorrect: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let ratio = Double(firstTryCorrect) / Double(total)
        switch ratio {
        case 0.85...: return 3
        case 0.5..<0.85: return 2
        default: return 1
        }
    }
}

/// Small deterministic generator so games can be replayed in tests.
struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    // SplitMix64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
