import Foundation

struct FocusTag: Codable, Identifiable {
    let id: String
    let key: String
    let category: String
    let label: String
    let description: String?
}

struct HighlightChip: Codable, Identifiable {
    let id: String
    let key: String
    let label: String
}

struct NextFocusChip: Codable, Identifiable {
    let id: String
    let key: String
    let label: String
}

struct Facility: Codable, Identifiable {
    let id: String
    let name: String
    let city: String?
    let isSaved: Bool
}

struct Coach: Codable, Identifiable {
    let id: String
    let displayName: String
    let isSaved: Bool
}

struct Program: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let isSaved: Bool
}
