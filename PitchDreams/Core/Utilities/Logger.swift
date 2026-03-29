import os

enum Log {
    static let api = Logger(subsystem: "com.pitchdreams.training", category: "API")
    static let auth = Logger(subsystem: "com.pitchdreams.training", category: "Auth")
    static let ui = Logger(subsystem: "com.pitchdreams.training", category: "UI")
}
