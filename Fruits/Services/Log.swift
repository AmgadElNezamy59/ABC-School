import os

/// Unified logging categories. Messages are visible in Console.app, never shown to users.
enum Log {
    private static let subsystem = "com.amgadElnezamy.Fruits"

    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let speech = Logger(subsystem: subsystem, category: "speech")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let content = Logger(subsystem: subsystem, category: "content")
}
