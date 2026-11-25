import Foundation
import Observation

/// The few preferences a parent may want to change. Stored in UserDefaults.
@MainActor
@Observable
final class AppSettings {
    enum Accent: String, CaseIterable, Identifiable, Sendable {
        case american = "en-US"
        case british = "en-GB"

        var id: String { rawValue }
        var languageCode: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .american: "American English"
            case .british: "British English"
            }
        }
    }

    private enum Key {
        static let accent = "settings.accent"
        static let autoplay = "settings.autoplay"
    }

    var accent: Accent {
        didSet { defaults.set(accent.rawValue, forKey: Key.accent) }
    }

    /// Say each word automatically when its card appears.
    var autoplay: Bool {
        didSet { defaults.set(autoplay, forKey: Key.autoplay) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        accent = defaults.string(forKey: Key.accent).flatMap(Accent.init(rawValue:)) ?? .american
        autoplay = defaults.object(forKey: Key.autoplay) as? Bool ?? true
    }
}
