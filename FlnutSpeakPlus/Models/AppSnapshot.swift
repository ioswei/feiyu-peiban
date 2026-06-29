import Foundation

struct AppSnapshot: Codable, Equatable {
    var userEmail: String
    var userAlias: String
    var userSignature: String
    var oceanBottles: [DriftBottle]
    var thrownBottles: [DriftBottle]
    var moodPosts: [MoodPost]
    var conversations: [Conversation]
    var notifications: [AppNotification]
    var caughtBottleIDs: [UUID]
    var caughtHistory: [CaughtBottleRecord]
    var savedBottleIDs: [UUID]
    var diaryEntries: [DiaryEntry]
    var unlockedAchievements: [String]
    var catchMoodFilter: CatchMoodFilter
    var companionMinutesTotal: Int
    var lastDiaryDate: String?
    var moodComments: [MoodComment]
    var blockedAliases: [String]
    var hiddenPostIDs: [UUID]
    var hiddenBottleIDs: [UUID]
    var hiddenCommentIDs: [UUID]
    var profileAvatarEmoji: String
    var submittedReports: [ContentReport]

    enum CodingKeys: String, CodingKey {
        case userEmail, userAlias, userSignature, oceanBottles, thrownBottles, moodPosts
        case conversations, notifications, caughtBottleIDs, caughtHistory
        case savedBottleIDs, diaryEntries, unlockedAchievements
        case catchMoodFilter, companionMinutesTotal, lastDiaryDate
        case moodComments, blockedAliases, hiddenPostIDs, hiddenBottleIDs, hiddenCommentIDs
        case profileAvatarEmoji, submittedReports
    }

    init(
        userEmail: String = "",
        userAlias: String,
        userSignature: String = "",
        oceanBottles: [DriftBottle],
        thrownBottles: [DriftBottle],
        moodPosts: [MoodPost],
        conversations: [Conversation],
        notifications: [AppNotification],
        caughtBottleIDs: [UUID],
        caughtHistory: [CaughtBottleRecord] = [],
        savedBottleIDs: [UUID] = [],
        diaryEntries: [DiaryEntry] = [],
        unlockedAchievements: [String] = [],
        catchMoodFilter: CatchMoodFilter = .any,
        companionMinutesTotal: Int = 0,
        lastDiaryDate: String? = nil,
        moodComments: [MoodComment] = [],
        blockedAliases: [String] = [],
        hiddenPostIDs: [UUID] = [],
        hiddenBottleIDs: [UUID] = [],
        hiddenCommentIDs: [UUID] = [],
        profileAvatarEmoji: String = "🌊",
        submittedReports: [ContentReport] = []
    ) {
        self.userEmail = userEmail
        self.userAlias = userAlias
        self.userSignature = userSignature
        self.oceanBottles = oceanBottles
        self.thrownBottles = thrownBottles
        self.moodPosts = moodPosts
        self.conversations = conversations
        self.notifications = notifications
        self.caughtBottleIDs = caughtBottleIDs
        self.caughtHistory = caughtHistory
        self.savedBottleIDs = savedBottleIDs
        self.diaryEntries = diaryEntries
        self.unlockedAchievements = unlockedAchievements
        self.catchMoodFilter = catchMoodFilter
        self.companionMinutesTotal = companionMinutesTotal
        self.lastDiaryDate = lastDiaryDate
        self.moodComments = moodComments
        self.blockedAliases = blockedAliases
        self.hiddenPostIDs = hiddenPostIDs
        self.hiddenBottleIDs = hiddenBottleIDs
        self.hiddenCommentIDs = hiddenCommentIDs
        self.profileAvatarEmoji = profileAvatarEmoji
        self.submittedReports = submittedReports
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userEmail = try c.decodeIfPresent(String.self, forKey: .userEmail) ?? ""
        userAlias = try c.decode(String.self, forKey: .userAlias)
        userSignature = try c.decodeIfPresent(String.self, forKey: .userSignature) ?? ""
        oceanBottles = try c.decode([DriftBottle].self, forKey: .oceanBottles)
        thrownBottles = try c.decode([DriftBottle].self, forKey: .thrownBottles)
        moodPosts = try c.decode([MoodPost].self, forKey: .moodPosts)
        conversations = try c.decode([Conversation].self, forKey: .conversations)
        notifications = try c.decode([AppNotification].self, forKey: .notifications)
        caughtBottleIDs = try c.decodeIfPresent([UUID].self, forKey: .caughtBottleIDs) ?? []
        caughtHistory = try c.decodeIfPresent([CaughtBottleRecord].self, forKey: .caughtHistory) ?? []
        savedBottleIDs = try c.decodeIfPresent([UUID].self, forKey: .savedBottleIDs) ?? []
        diaryEntries = try c.decodeIfPresent([DiaryEntry].self, forKey: .diaryEntries) ?? []
        unlockedAchievements = try c.decodeIfPresent([String].self, forKey: .unlockedAchievements) ?? []
        catchMoodFilter = try c.decodeIfPresent(CatchMoodFilter.self, forKey: .catchMoodFilter) ?? .any
        companionMinutesTotal = try c.decodeIfPresent(Int.self, forKey: .companionMinutesTotal) ?? 0
        lastDiaryDate = try c.decodeIfPresent(String.self, forKey: .lastDiaryDate)
        moodComments = try c.decodeIfPresent([MoodComment].self, forKey: .moodComments) ?? []
        blockedAliases = try c.decodeIfPresent([String].self, forKey: .blockedAliases) ?? []
        hiddenPostIDs = try c.decodeIfPresent([UUID].self, forKey: .hiddenPostIDs) ?? []
        hiddenBottleIDs = try c.decodeIfPresent([UUID].self, forKey: .hiddenBottleIDs) ?? []
        hiddenCommentIDs = try c.decodeIfPresent([UUID].self, forKey: .hiddenCommentIDs) ?? []
        profileAvatarEmoji = try c.decodeIfPresent(String.self, forKey: .profileAvatarEmoji) ?? "🌊"
        submittedReports = try c.decodeIfPresent([ContentReport].self, forKey: .submittedReports) ?? []
    }
}
