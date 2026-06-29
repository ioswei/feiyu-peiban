import Foundation

enum BottleMood: String, CaseIterable, Codable, Identifiable {
    case lonely = "孤独"
    case hopeful = "期待"
    case melancholy = "忧郁"
    case grateful = "感恩"
    case restless = "迷茫"
    case peaceful = "平静"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .lonely: "🌙"
        case .hopeful: "✨"
        case .melancholy: "🌧️"
        case .grateful: "🌸"
        case .restless: "🍃"
        case .peaceful: "🌊"
        }
    }
}

struct DriftBottle: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var mood: BottleMood
    var authorAlias: String
    var createdAt: Date
    var isAnonymous: Bool

    init(
        id: UUID = UUID(),
        content: String,
        mood: BottleMood,
        authorAlias: String,
        createdAt: Date = Date(),
        isAnonymous: Bool = true
    ) {
        self.id = id
        self.content = content
        self.mood = mood
        self.authorAlias = authorAlias
        self.createdAt = createdAt
        self.isAnonymous = isAnonymous
    }
}

struct MoodPost: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var mood: BottleMood
    var authorAlias: String
    var createdAt: Date
    var likeCount: Int

    init(
        id: UUID = UUID(),
        content: String,
        mood: BottleMood,
        authorAlias: String,
        createdAt: Date = Date(),
        likeCount: Int = 0
    ) {
        self.id = id
        self.content = content
        self.mood = mood
        self.authorAlias = authorAlias
        self.createdAt = createdAt
        self.likeCount = likeCount
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var isFromMe: Bool
    var sentAt: Date

    init(id: UUID = UUID(), content: String, isFromMe: Bool, sentAt: Date = Date()) {
        self.id = id
        self.content = content
        self.isFromMe = isFromMe
        self.sentAt = sentAt
    }
}

struct Conversation: Identifiable, Codable, Equatable {
    let id: UUID
    var partnerAlias: String
    var partnerMood: BottleMood
    var lastMessage: String
    var lastMessageAt: Date
    var unreadCount: Int
    var messages: [ChatMessage]
    var originBottleContent: String

    init(
        id: UUID = UUID(),
        partnerAlias: String,
        partnerMood: BottleMood,
        lastMessage: String,
        lastMessageAt: Date = Date(),
        unreadCount: Int = 0,
        messages: [ChatMessage] = [],
        originBottleContent: String
    ) {
        self.id = id
        self.partnerAlias = partnerAlias
        self.partnerMood = partnerMood
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
        self.messages = messages
        self.originBottleContent = originBottleContent
    }
}

struct AppNotification: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var isRead: Bool
    var kind: NotificationKind

    enum NotificationKind: String, Codable {
        case bottleCaught
        case newMessage
        case encounter
        case reminder
    }

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        createdAt: Date = Date(),
        isRead: Bool = false,
        kind: NotificationKind
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.isRead = isRead
        self.kind = kind
    }
}
