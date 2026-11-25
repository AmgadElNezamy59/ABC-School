import SwiftUI

@main
struct ABCSchoolApp: App {
    @State private var settings: AppSettings
    @State private var progress: ProgressStore
    @State private var speaker: Speaker

    init() {
        let launch = LaunchOptions.current
        let settings = AppSettings(defaults: launch.defaults)
        _settings = State(initialValue: settings)
        _progress = State(initialValue: ProgressStore(defaults: launch.defaults))
        _speaker = State(initialValue: Speaker(settings: settings))

        AudioSession.useForPlayback()
        Typography.configureNavigationBar()
        if launch.disablesAnimations {
            UIView.setAnimationsEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(progress)
                .environment(speaker)
                .fontDesign(.rounded)
                .tint(.brand)
        }
    }
}

/// Launch arguments used by UI tests: a clean, isolated store and no animations.
struct LaunchOptions {
    let defaults: UserDefaults
    let disablesAnimations: Bool

    static var current: LaunchOptions {
        guard ProcessInfo.processInfo.arguments.contains("-ui-testing") else {
            return LaunchOptions(defaults: .standard, disablesAnimations: false)
        }
        let suiteName = "ABCSchool.UITests"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return LaunchOptions(defaults: defaults, disablesAnimations: true)
    }
}
