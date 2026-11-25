import SwiftUI

/// The grown-ups' sheet: voice, auto-play, speech check status, reset, about.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(Speaker.self) private var speaker
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var confirmsReset = false
    @State private var speechStatus: SpeechCheckStatus?

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section {
                    Picker("Voice", selection: $settings.accent) {
                        ForEach(AppSettings.Accent.allCases) { accent in
                            Text(accent.title).tag(accent)
                        }
                    }
                    Button {
                        speaker.say(String(localized: "Hello! Let's learn English together."), tag: "settings.sample")
                    } label: {
                        Label("Hear a Sample", systemImage: "speaker.wave.2.fill")
                    }
                    Toggle("Say Words Automatically", isOn: $settings.autoplay)
                        .accessibilityIdentifier("settings.autoplay")
                } header: {
                    Text("Voice")
                } footer: {
                    Text("Words with a human recording always use it at normal speed.")
                }

                Section {
                    LabeledContent("Speech Check") {
                        Text(statusTitle)
                    }
                    if speechStatus == .denied {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    }
                } header: {
                    Text("Say It")
                } footer: {
                    Text(statusFooter)
                }

                Section {
                    Button("Reset Progress", role: .destructive) { confirmsReset = true }
                        .accessibilityIdentifier("settings.reset")
                } footer: {
                    Text("Clears every star and best game score.")
                }

                Section("About") {
                    LabeledContent("Version", value: Self.appVersion)
                    Text("ABC School works completely offline. There are no accounts, ads or tracking, and voice recordings are deleted as soon as practice ends.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("settings.done")
                }
            }
            .confirmationDialog("Reset all progress?", isPresented: $confirmsReset, titleVisibility: .visible) {
                Button("Reset Progress", role: .destructive) { progress.reset() }
                    .accessibilityIdentifier("settings.confirmReset")
            } message: {
                Text("All stars and best scores will be cleared. This can't be undone.")
            }
            .task(id: settings.accent) {
                speechStatus = SpeechChecker(languageCode: settings.accent.languageCode).status
            }
            .onDisappear { speaker.stop() }
        }
    }

    private var statusTitle: LocalizedStringKey {
        switch speechStatus {
        case .available: "On"
        case .needsPermission: "Asks when first used"
        case .denied: "Off"
        case .unsupported: "Not available"
        case nil: "Checking…"
        }
    }

    private var statusFooter: LocalizedStringKey {
        switch speechStatus {
        case .available, .needsPermission, nil:
            "Your child's voice is checked on this device and never leaves it."
        case .denied:
            "Speech recognition is turned off for ABC School, so a grown-up listens and confirms each try."
        case .unsupported:
            "This device can't check speech offline, so a grown-up listens and confirms each try."
        }
    }

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .previewEnvironment()
}
