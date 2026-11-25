#if DEBUG
import SwiftUI

/// Sample data and services for SwiftUI previews only.
@MainActor
enum PreviewSupport {
    static let categories: [Category] = (try? Catalog.load()) ?? []
    static var fruits: Category { categories.first { $0.id == "fruits" } ?? categories[0] }

    static let defaults = UserDefaults(suiteName: "previews") ?? .standard
    static let settings = AppSettings(defaults: defaults)
    static let progress: ProgressStore = {
        let store = ProgressStore(defaults: defaults)
        store.recordPractice(stars: 3, for: "fruits.apple")
        store.recordPractice(stars: 2, for: "fruits.banana")
        return store
    }()
    static let speaker = Speaker(settings: settings)
}

extension View {
    func previewEnvironment() -> some View {
        environment(PreviewSupport.settings)
            .environment(PreviewSupport.progress)
            .environment(PreviewSupport.speaker)
            .fontDesign(.rounded)
            .tint(.brand)
    }
}
#endif
