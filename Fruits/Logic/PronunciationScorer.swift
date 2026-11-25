import Foundation

/// Turns what speech recognition heard into 0–3 stars.
///
/// Kids' speech is messy and recognizers are imperfect, so the scorer is forgiving:
/// it looks for the word anywhere in the phrase, accepts known alternatives
/// ("bee" for B), and gives partial credit for near misses.
enum PronunciationScorer {
    struct Score: Equatable, Sendable {
        let stars: Int
        /// The transcription that earned the score, if any.
        let heard: String?
    }

    /// - Parameters:
    ///   - candidates: Transcriptions from best to worst guess.
    ///   - answers: Every spelling that counts as correct.
    static func score(candidates: [String], answers: [String]) -> Score {
        let targets = answers.map(normalize).filter { !$0.isEmpty }
        guard !targets.isEmpty else { return Score(stars: 0, heard: nil) }

        var best = Score(stars: 0, heard: nil)
        for (rank, candidate) in candidates.enumerated() {
            let phrase = normalize(candidate)
            guard !phrase.isEmpty else { continue }
            let similarity = targets.map { bestSimilarity(of: $0, in: phrase) }.max() ?? 0
            var stars = stars(for: similarity)
            // Only the recognizer's top guess can earn a perfect score.
            if rank > 0 { stars = min(stars, 2) }
            if stars > best.stars { best = Score(stars: stars, heard: candidate) }
            if best.stars == 3 { break }
        }
        return best
    }

    static func stars(for similarity: Double) -> Int {
        switch similarity {
        case 1...: 3
        case 0.75..<1: 2
        case 0.5..<0.75: 1
        default: 0
        }
    }

    /// Best match between `target` and any run of words in `phrase` with the same word count,
    /// so "an apple" still matches "apple".
    static func bestSimilarity(of target: String, in phrase: String) -> Double {
        let targetWordCount = target.split(separator: " ").count
        let words = phrase.split(separator: " ")
        var best = similarity(target, phrase)
        guard words.count > targetWordCount else { return best }
        for start in 0...(words.count - targetWordCount) {
            let window = words[start..<(start + targetWordCount)].joined(separator: " ")
            best = max(best, similarity(target, window))
        }
        return best
    }

    /// 1.0 for identical strings, falling towards 0 as the edit distance grows.
    static func similarity(_ lhs: String, _ rhs: String) -> Double {
        let length = max(lhs.count, rhs.count)
        guard length > 0 else { return 1 }
        return 1 - Double(editDistance(Array(lhs), Array(rhs))) / Double(length)
    }

    /// Lowercases, strips accents and punctuation, and collapses whitespace.
    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US"))
        let cleaned = folded.map { $0.isLetter || $0.isNumber ? $0 : " " }
        return String(cleaned).split(separator: " ").joined(separator: " ")
    }

    /// Levenshtein distance using two rolling rows.
    private static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            swap(&previous, &current)
        }
        return previous[b.count]
    }
}
