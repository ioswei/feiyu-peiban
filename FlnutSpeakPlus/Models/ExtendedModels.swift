import Foundation

struct CaughtBottleRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var bottle: DriftBottle
    var caughtAt: Date

    init(id: UUID = UUID(), bottle: DriftBottle, caughtAt: Date = Date()) {
        self.id = id
        self.bottle = bottle
        self.caughtAt = caughtAt
    }
}

struct DiaryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var mood: BottleMood
    var createdAt: Date

    init(id: UUID = UUID(), content: String, mood: BottleMood, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.mood = mood
        self.createdAt = createdAt
    }
}

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let requiredCount: Int

    var badgeID: String { id }
}

enum CatchMoodFilter: String, Codable, CaseIterable, Identifiable {
    case any = "不限"
    case lonely = "孤独"
    case hopeful = "期待"
    case melancholy = "忧郁"
    case grateful = "感恩"
    case restless = "迷茫"
    case peaceful = "平静"

    var id: String { rawValue }

    var bottleMood: BottleMood? {
        switch self {
        case .any: nil
        case .lonely: .lonely
        case .hopeful: .hopeful
        case .melancholy: .melancholy
        case .grateful: .grateful
        case .restless: .restless
        case .peaceful: .peaceful
        }
    }

    var emoji: String {
        bottleMood?.emoji ?? "🌊"
    }
}
