import Foundation
import Testing
import UIKit
@testable import Fruits

/// Guards the bundled content: every word must be playable, drawable and scorable on a real device.
@MainActor
struct CatalogTests {
    let categories: [Fruits.Category]

    init() throws {
        categories = try Catalog.load()
    }

    @Test func loadsSixTopicsInOrder() {
        #expect(categories.map(\.id) == ["alphabet", "fruits", "animals", "colors", "numbers", "shapes"])
        #expect(categories.flatMap(\.words).count == 78)
    }

    @Test func wordIDsAreUniqueAndNamespacedByTopic() {
        let ids = categories.flatMap(\.words).map(\.id)
        #expect(Set(ids).count == ids.count)
        for category in categories {
            for word in category.words {
                #expect(word.id.hasPrefix("\(category.id)."), "\(word.id) should start with \(category.id).")
            }
        }
    }

    @Test func everyTopicHasEnoughWordsForAFullGame() {
        for category in categories {
            #expect(category.words.count >= GameBuilder.optionsPerRound, "\(category.id) is too small for the game")
        }
    }

    @Test func everyWordHasTextAndASentence() {
        for word in categories.flatMap(\.words) {
            #expect(!word.text.trimmingCharacters(in: .whitespaces).isEmpty)
            #expect(word.sentence?.isEmpty == false, "\(word.id) needs an example sentence")
        }
    }

    @Test func everyPhotoExistsInTheAssetCatalog() {
        for visual in allVisuals {
            if case .photo(let name) = visual {
                #expect(UIImage(named: name) != nil, "Missing image \(name)")
            }
        }
    }

    @Test func everyShapeIsARealSFSymbol() {
        for visual in allVisuals {
            if case .shape(let symbol) = visual {
                #expect(UIImage(systemName: symbol) != nil, "Unknown SF Symbol \(symbol)")
            }
        }
    }

    @Test func numbersAndColorsAreValid() {
        for visual in allVisuals {
            switch visual {
            case .number(let value): #expect((1...10).contains(value))
            case .color(let hex): #expect(HexColor(hex) != nil, "Bad color \(hex)")
            default: break
            }
        }
    }

    /// The device file system is case-sensitive (the Simulator's usually isn't),
    /// so compare against the exact file names in the bundle.
    @Test func everyRecordingExistsWithExactFileNameCase() throws {
        let bundleFiles = Set(try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath))
        let recordings = categories.flatMap(\.words).compactMap(\.audio)
        #expect(recordings.count == 4)
        for file in recordings {
            #expect(bundleFiles.contains(file), "Recording \(file) is missing or has the wrong case")
        }
        for effect in Speaker.Effect.allCases {
            #expect(bundleFiles.contains("\(effect.rawValue).wav"), "Sound effect \(effect.rawValue) is missing")
        }
    }

    @Test func gradientsAreValidHexPairs() {
        for category in categories {
            #expect(category.colors.count == 2)
            #expect(category.colors.allSatisfy { HexColor($0) != nil })
            for word in category.words {
                if let colors = word.colors {
                    #expect(colors.count == 2, "\(word.id) needs two gradient colors")
                    #expect(colors.allSatisfy { HexColor($0) != nil }, "\(word.id) has an invalid color")
                }
            }
        }
    }

    /// Topic titles are white on the topic gradient; large bold text needs at least 3:1 (WCAG AA).
    @Test func whiteTitlesAreReadableOnEveryTopicColor() {
        for category in categories {
            for hex in category.colors {
                let contrast = HexColor(hex).map { $0.contrast(with: .white) } ?? 0
                #expect(contrast >= 3, "White on \(hex) (\(category.id)) is only \(contrast):1")
            }
        }
    }

    @Test func numbersAcceptDigits() throws {
        let numbers = try #require(categories.first { $0.id == "numbers" })
        for (offset, word) in numbers.words.enumerated() {
            #expect(word.answers.contains(String(offset + 1)), "\(word.text) should accept \(offset + 1)")
        }
    }

    private var allVisuals: [WordVisual] {
        categories.map(\.cover) + categories.flatMap(\.words).map(\.visual)
    }
}

struct WordVisualDecodingTests {
    private func decode(_ json: String) throws -> WordVisual {
        try JSONDecoder().decode(WordVisual.self, from: Data(json.utf8))
    }

    @Test func decodesEveryKind() throws {
        #expect(try decode(#"{"kind":"photo","value":"apple"}"#) == .photo("apple"))
        #expect(try decode(#"{"kind":"emoji","value":"🐱"}"#) == .emoji("🐱"))
        #expect(try decode(#"{"kind":"text","value":"Aa","badge":"🍎"}"#) == .text("Aa", badge: "🍎"))
        #expect(try decode(#"{"kind":"text","value":"ABC"}"#) == .text("ABC", badge: nil))
        #expect(try decode(#"{"kind":"number","value":"7"}"#) == .number(7))
        #expect(try decode(##"{"kind":"color","value":"#FFFFFF"}"##) == .color("#FFFFFF"))
        #expect(try decode(#"{"kind":"shape","value":"star.fill"}"#) == .shape("star.fill"))
    }

    @Test func rejectsUnknownKindsAndBadNumbers() {
        #expect(throws: DecodingError.self) { try decode(#"{"kind":"video","value":"x"}"#) }
        #expect(throws: DecodingError.self) { try decode(#"{"kind":"number","value":"seven"}"#) }
    }
}
