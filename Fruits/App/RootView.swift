import SwiftUI

/// Loads the word catalog and shows Home, or a recoverable error if loading fails.
struct RootView: View {
    @State private var catalog = Result { try Catalog.load() }

    var body: some View {
        switch catalog {
        case .success(let categories):
            HomeView(categories: categories)
        case .failure(let error):
            ContentUnavailableView {
                Label("Lessons Didn't Load", systemImage: "exclamationmark.triangle.fill")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("Try Again") { catalog = Result { try Catalog.load() } }
                    .buttonStyle(ChunkyButtonStyle())
            }
            .background(Color.appBackground.ignoresSafeArea())
            .onAppear { Log.content.error("Catalog failed to load: \(error.localizedDescription)") }
        }
    }
}

/// Every screen pushed onto the main navigation stack.
enum Route: Hashable {
    case topic(Category)
    case learn(Category, startIndex: Int)
}
