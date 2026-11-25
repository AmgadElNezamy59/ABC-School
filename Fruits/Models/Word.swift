import Foundation

/// A topic such as "Fruits" or "Alphabet". Loaded from `catalog.json`.
struct Category: Identifiable, Hashable, Decodable, Sendable {
    let id: String
    let title: String
    let cover: WordVisual
    /// Two hex colors used for the topic's gradient.
    let colors: [String]
    let words: [Word]

    // Identity is the id; the words never change at runtime.
    static func == (lhs: Category, rhs: Category) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A single word a child can hear, say and play with.
struct Word: Identifiable, Hashable, Decodable, Sendable {
    let id: String
    /// The word as written, e.g. "Apple" or "B".
    let text: String
    /// Optional syllable breakdown shown under the word, e.g. "Ap·ple".
    let syllables: String?
    /// A short example sentence that uses the word.
    let sentence: String?
    let visual: WordVisual
    /// Optional gradient for the word's stage; falls back to the topic's colors.
    let colors: [String]?
    /// File name of a bundled human recording, e.g. "apple.mp3".
    let audio: String?
    /// Other spellings speech recognition may return for a correct answer,
    /// e.g. "bee" for "B" or "7" for "Seven".
    let accepted: [String]?

    /// Every written form that counts as saying this word correctly.
    var answers: [String] { [text] + (accepted ?? []) }

    static func == (lhs: Word, rhs: Word) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// What a word looks like on its card.
enum WordVisual: Hashable, Sendable {
    /// A photo from the asset catalog.
    case photo(String)
    case emoji(String)
    /// Large letters, with an optional emoji badge (e.g. "Aa" with 🍎).
    case text(String, badge: String?)
    /// A digit with a ten-frame of dots for counting.
    case number(Int)
    /// A paint swatch, given as a hex color.
    case color(String)
    /// An SF Symbol, used for shapes.
    case shape(String)
}

extension WordVisual: Decodable {
    private enum CodingKeys: String, CodingKey { case kind, value, badge }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        let value = try container.decode(String.self, forKey: .value)
        switch kind {
        case "photo": self = .photo(value)
        case "emoji": self = .emoji(value)
        case "text": self = .text(value, badge: try container.decodeIfPresent(String.self, forKey: .badge))
        case "color": self = .color(value)
        case "shape": self = .shape(value)
        case "number":
            guard let number = Int(value) else {
                throw DecodingError.dataCorruptedError(forKey: .value, in: container,
                                                       debugDescription: "Number visual needs an integer, got \(value)")
            }
            self = .number(number)
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container,
                                                   debugDescription: "Unknown visual kind \(kind)")
        }
    }
}
