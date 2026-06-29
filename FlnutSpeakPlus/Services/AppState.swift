import Combine
import Foundation
import SwiftUI
import UIKit

enum MainTab: Hashable {
    case ocean
    case square
    case messages
    case profile
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isLoggedIn = false
    @Published private(set) var userEmail = ""
    @Published var userAlias: String
    @Published var userSignature: String
    @Published var profileAvatarEmoji: String = "🌊"
    @Published var selectedMainTab: MainTab = .ocean
    @Published var pendingOpenConversationID: UUID?
    @Published var pendingShowNotifications = false
    @Published var oceanBottles: [DriftBottle] = []
    @Published var thrownBottles: [DriftBottle] = []
    @Published var moodPosts: [MoodPost] = []
    @Published var conversations: [Conversation] = []
    @Published var notifications: [AppNotification] = []
    @Published var lastCaughtBottle: DriftBottle?
    @Published var caughtHistory: [CaughtBottleRecord] = []
    @Published var savedBottleIDs: Set<UUID> = []
    @Published var diaryEntries: [DiaryEntry] = []
    @Published var unlockedAchievements: Set<String> = []
    @Published var catchMoodFilter: CatchMoodFilter = .any
    @Published var companionMinutesTotal: Int = 0
    @Published var moodComments: [MoodComment] = []
    @Published var blockedAliases: Set<String> = []
    @Published var hiddenPostIDs: Set<UUID> = []
    @Published var hiddenBottleIDs: Set<UUID> = []
    @Published var hiddenCommentIDs: Set<UUID> = []
    @Published private(set) var submittedReports: [ContentReport] = []

    private var caughtBottleIDs: Set<UUID> = []
    private var lastDiaryDate: String?
    private var pendingLegacySnapshot: AppSnapshot?

    init() {
        userAlias = ""
        userSignature = ""
        AuthStore.ensureBuiltInDemoAccountRegistered()
        AuthStore.backfillLastLoggedInEmailIfNeeded()
        if let email = AuthStore.currentSessionEmail {
            bootstrapLoggedInUser(email: email)
        } else if let legacy = LocalStore.loadLegacy() {
            pendingLegacySnapshot = legacy
        }
    }

    @discardableResult
    func loginWithVerificationCode(_ email: String, code: String) -> AuthOutcome {
        let outcome = AuthStore.loginOrRegister(email: email, verificationCode: code)
        guard case .success(let isNewUser) = outcome else { return outcome }

        let normalized = AuthStore.normalizeEmail(email)
        userEmail = normalized
        isLoggedIn = true
        AuthStore.setSession(normalized)

        if isNewUser {
            setupNewUserAccount(email: normalized)
            addNotification(
                title: "欢迎加入飞语陪伴",
                body: "账号已创建，你的海洋之旅开始了。",
                kind: .encounter
            )
        } else {
            loadUserSnapshot(email: normalized)
        }

        persist()
        return outcome
    }

    func logout() {
        if isLoggedIn {
            persist()
        }
        isLoggedIn = false
        userEmail = ""
        AuthStore.clearSession()
        selectedMainTab = .ocean
        pendingOpenConversationID = nil
        pendingShowNotifications = false
        clearInMemoryState()
    }

    func openOceanTab() {
        selectedMainTab = .ocean
    }

    func openMessagesTab(conversationID: UUID? = nil, showNotifications: Bool = false) {
        selectedMainTab = .messages
        if let conversationID {
            pendingOpenConversationID = conversationID
        }
        if showNotifications {
            pendingShowNotifications = true
        }
    }

    private func bootstrapLoggedInUser(email: String) {
        userEmail = email
        isLoggedIn = true
        if let snapshot = LocalStore.load(for: email) {
            applyLoadedSnapshot(snapshot, email: email)
        } else if let legacy = LocalStore.loadLegacy() {
            apply(legacy)
            pendingLegacySnapshot = nil
            LocalStore.clearLegacy()
            persist()
        } else {
            setupNewUserAccount(email: email)
            persist()
        }
    }

    private func setupNewUserAccount(email: String) {
        if let legacy = pendingLegacySnapshot {
            apply(legacy)
            userEmail = email
            pendingLegacySnapshot = nil
            LocalStore.clearLegacy()
            return
        }

        if let existing = LocalStore.load(for: email) {
            applyLoadedSnapshot(existing, email: email)
            return
        }

        let alias = AuthStore.suggestedAlias(for: email)
        userAlias = alias
        userSignature = ""
        apply(localSeedSnapshot(for: email, alias: alias))
        userEmail = email
    }

    private func loadUserSnapshot(email: String) {
        if let snapshot = LocalStore.load(for: email) {
            applyLoadedSnapshot(snapshot, email: email)
        } else {
            setupNewUserAccount(email: email)
        }
    }

    private func localSeedSnapshot(for email: String, alias: String) -> AppSnapshot {
        if AuthStore.isBuiltInDemoEmail(email) {
            return MockData.makeRichLocalSnapshot(userAlias: alias)
        }
        return MockData.makeInitialSnapshot(userAlias: alias)
    }

    private func applyLoadedSnapshot(_ snapshot: AppSnapshot, email: String) {
        if shouldRestoreLocalSeed(afterWrongEmptyMigration: email, snapshot: snapshot) {
            let alias = snapshot.userAlias.isEmpty ? AuthStore.suggestedAlias(for: email) : snapshot.userAlias
            apply(localSeedSnapshot(for: email, alias: alias))
            clearWrongEmptyMigrationFlag(for: email)
        } else if AuthStore.isBuiltInDemoEmail(email), snapshot.oceanBottles.count < 12 {
            let alias = snapshot.userAlias.isEmpty ? AuthStore.suggestedAlias(for: email) : snapshot.userAlias
            apply(MockData.makeRichLocalSnapshot(userAlias: alias))
        } else {
            apply(snapshot)
        }
        userEmail = email
        persist()
    }

    private static let wrongEmptyMigrationKey = "feiyu.migration.emptyDemoContent"

    /// 恢复曾被误清空的本地种子数据
    private func shouldRestoreLocalSeed(afterWrongEmptyMigration email: String, snapshot: AppSnapshot) -> Bool {
        let key = Self.wrongEmptyMigrationKey + ".\(AuthStore.normalizeEmail(email))"
        guard UserDefaults.standard.bool(forKey: key) else { return false }
        return snapshot.oceanBottles.isEmpty
            && snapshot.conversations.isEmpty
            && snapshot.moodPosts.isEmpty
    }

    private func clearWrongEmptyMigrationFlag(for email: String) {
        let key = Self.wrongEmptyMigrationKey + ".\(AuthStore.normalizeEmail(email))"
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func clearInMemoryState() {
        userAlias = ""
        userSignature = ""
        oceanBottles = []
        thrownBottles = []
        moodPosts = []
        conversations = []
        notifications = []
        lastCaughtBottle = nil
        caughtHistory = []
        savedBottleIDs = []
        diaryEntries = []
        unlockedAchievements = []
        catchMoodFilter = .any
        companionMinutesTotal = 0
        moodComments = []
        blockedAliases = []
        hiddenPostIDs = []
        hiddenBottleIDs = []
        hiddenCommentIDs = []
        submittedReports = []
        profileAvatarEmoji = "🌊"
        caughtBottleIDs = []
        lastDiaryDate = nil
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var unreadMessageCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    var catchableBottleCount: Int {
        availableBottlesForCatch().count
    }

    var dailyWhisper: String {
        MockData.dailyWhisper()
    }

    var diaryStreakDays: Int {
        guard !diaryEntries.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sorted = diaryEntries.map { calendar.startOfDay(for: $0.createdAt) }.sorted(by: >)
        var streak = 1
        var cursor = sorted[0]
        for day in sorted.dropFirst() {
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            if calendar.isDate(day, inSameDayAs: prev) {
                streak += 1
                cursor = day
            } else if !calendar.isDate(day, inSameDayAs: cursor) {
                break
            }
        }
        return streak
    }

    var savedBottles: [DriftBottle] {
        caughtHistory
            .map(\.bottle)
            .filter { savedBottleIDs.contains($0.id) }
    }

    var blockedUsers: [String] {
        blockedAliases.sorted()
    }

    var profileBadgeTitle: String {
        let activityScore = thrownBottles.count + caughtHistory.count + diaryEntries.count + myMoodPostCount
        switch activityScore {
        case 0..<3: return "初到海边"
        case 3..<10: return "飞语旅人"
        case 10..<25: return "深蓝旅者"
        default: return "海洋守护者"
        }
    }

    var memberSinceText: String? {
        guard !userEmail.isEmpty, let date = AuthStore.accountCreatedAt(for: userEmail) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    var myMoodPostCount: Int {
        moodPosts.filter { $0.authorAlias == userAlias }.count
    }

    var achievementProgress: (unlocked: Int, total: Int) {
        (unlockedAchievements.count, MockData.achievements.count)
    }

    func achievementMetric(for achievement: Achievement) -> Int {
        let metrics: [String: Int] = [
            "first_throw": thrownBottles.isEmpty ? 0 : 1,
            "first_catch": caughtHistory.isEmpty ? 0 : 1,
            "first_encounter": conversations.isEmpty ? 0 : 1,
            "mood_voice": myMoodPostCount > 0 ? 1 : 0,
            "diary_keeper": diaryEntries.isEmpty ? 0 : 1,
            "throw_5": thrownBottles.count,
            "catch_5": caughtHistory.count,
            "companion_30": companionMinutesTotal
        ]
        return metrics[achievement.id] ?? 0
    }

    func achievementProgressFraction(for achievement: Achievement) -> Double {
        let current = achievementMetric(for: achievement)
        guard achievement.requiredCount > 0 else { return 0 }
        return min(1, Double(current) / Double(achievement.requiredCount))
    }

    func dominantDiaryMood() -> BottleMood? {
        guard !diaryEntries.isEmpty else { return nil }
        let grouped = Dictionary(grouping: diaryEntries, by: \.mood)
        return grouped.max { $0.value.count < $1.value.count }?.key
    }

    func visibleConversations() -> [Conversation] {
        conversations.filter { !blockedAliases.contains($0.partnerAlias) }
    }

    func visibleMoodPosts(filter: CatchMoodFilter = .any) -> [MoodPost] {
        moodPosts.filter { post in
            !blockedAliases.contains(post.authorAlias) && !hiddenPostIDs.contains(post.id)
        }.filter { post in
            guard let mood = filter.bottleMood else { return true }
            return post.mood == mood
        }
    }

    func comments(for postID: UUID) -> [MoodComment] {
        moodComments
            .filter {
                $0.postID == postID
                    && !blockedAliases.contains($0.authorAlias)
                    && !hiddenCommentIDs.contains($0.id)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func commentCount(for postID: UUID) -> Int {
        comments(for: postID).count
    }

    func isBlocked(_ alias: String) -> Bool {
        blockedAliases.contains(alias)
    }

    func post(by id: UUID) -> MoodPost? {
        moodPosts.first { $0.id == id }
    }

    func addComment(to postID: UUID, content: String) -> Bool {
        guard ContentSafety.isAllowed(content) else { return false }
        let comment = MoodComment(postID: postID, authorAlias: userAlias, content: content.trimmingCharacters(in: .whitespacesAndNewlines))
        moodComments.append(comment)
        persist()
        return true
    }

    func hidePost(_ post: MoodPost) {
        hiddenPostIDs.insert(post.id)
        persist()
    }

    func hideComment(_ comment: MoodComment) {
        hiddenCommentIDs.insert(comment.id)
        persist()
    }

    func reportPost(_ post: MoodPost, reason: ReportReason) {
        hiddenPostIDs.insert(post.id)
        submitReport(
            contentType: "心情动态",
            contentID: post.id,
            targetAlias: post.authorAlias,
            reason: reason,
            excerpt: post.content
        )
    }

    func reportComment(_ comment: MoodComment, reason: ReportReason) {
        hiddenCommentIDs.insert(comment.id)
        submitReport(
            contentType: "评论",
            contentID: comment.id,
            targetAlias: comment.authorAlias,
            reason: reason,
            excerpt: comment.content
        )
    }

    func reportBottle(_ bottle: DriftBottle, reason: ReportReason) {
        hiddenBottleIDs.insert(bottle.id)
        let alias = bottle.isAnonymous ? nil : bottle.authorAlias
        submitReport(
            contentType: "漂流瓶",
            contentID: bottle.id,
            targetAlias: alias,
            reason: reason,
            excerpt: bottle.content
        )
    }

    func reportConversation(_ conversation: Conversation, reason: ReportReason) {
        let lastPeerMessage = conversation.messages.last(where: { !$0.isFromMe })?.content ?? conversation.lastMessage
        conversations.removeAll { $0.id == conversation.id }
        submitReport(
            contentType: "聊天会话",
            contentID: conversation.id,
            targetAlias: conversation.partnerAlias,
            reason: reason,
            excerpt: lastPeerMessage
        )
    }

    private func submitReport(
        contentType: String,
        contentID: UUID,
        targetAlias: String?,
        reason: ReportReason,
        excerpt: String
    ) {
        let report = ContentReport(
            contentType: contentType,
            contentID: contentID,
            targetAlias: targetAlias,
            reason: reason,
            excerpt: ContentSafety.excerpt(excerpt),
            reporterEmail: userEmail
        )
        submittedReports.insert(report, at: 0)

        if let url = AppSupport.reportMailURL(for: report) {
            UIApplication.shared.open(url)
        }

        addNotification(
            title: "举报已提交",
            body: "我们已记录对该\(contentType)的反馈（\(reason.rawValue)），将在 \(AppSupport.reviewResponseHours) 小时内处理。",
            kind: .reminder
        )
        persist()
    }

    func blockUser(_ alias: String) {
        guard alias != userAlias else { return }
        blockedAliases.insert(alias)
        conversations.removeAll { $0.partnerAlias == alias }
        addNotification(
            title: "已屏蔽该用户",
            body: "你将不再看到 \(alias) 的瓶子、动态与聊天。",
            kind: .reminder
        )
        persist()
    }

    func unblockUser(_ alias: String) {
        blockedAliases.remove(alias)
        persist()
    }

    func deleteAccount() {
        guard isLoggedIn, !userEmail.isEmpty else { return }
        let email = userEmail
        LocalStore.clear(for: email)
        AuthStore.deleteAccount(email: email)
        logout()
    }

    @discardableResult
    func throwBottle(content: String, mood: BottleMood, isAnonymous: Bool) -> Bool {
        guard ContentSafety.isAllowed(content) else { return false }
        let bottle = DriftBottle(
            content: content,
            mood: mood,
            authorAlias: userAlias,
            isAnonymous: isAnonymous
        )
        thrownBottles.insert(bottle, at: 0)
        oceanBottles.insert(bottle, at: 0)
        addNotification(
            title: "漂流瓶已出发",
            body: "你的心事正漂向大海，等待另一个灵魂捡起。",
            kind: .reminder
        )
        checkAchievements()
        persist()
        return true
    }

    @discardableResult
    func catchRandomBottle() -> DriftBottle? {
        let available = availableBottlesForCatch()
        guard let bottle = available.randomElement() else { return nil }

        caughtBottleIDs.insert(bottle.id)
        caughtHistory.insert(CaughtBottleRecord(bottle: bottle), at: 0)
        lastCaughtBottle = bottle
        addNotification(
            title: "你捡到了一个漂流瓶",
            body: "一位\(bottle.mood.rawValue)的灵魂向你漂来…",
            kind: .bottleCaught
        )
        checkAchievements()
        persist()
        return bottle
    }

    @discardableResult
    func startEncounter(from bottle: DriftBottle) -> UUID {
        let partner = bottle.isAnonymous
            ? MockData.randomAlias(excluding: userAlias)
            : bottle.authorAlias

        let greeting = ChatMessage(
            content: "你好，我捡到了你的瓶子：「\(String(bottle.content.prefix(20)))…」",
            isFromMe: false
        )
        let conversation = Conversation(
            partnerAlias: partner,
            partnerMood: bottle.mood,
            lastMessage: greeting.content,
            unreadCount: 1,
            messages: [greeting],
            originBottleContent: bottle.content
        )
        conversations.insert(conversation, at: 0)
        addNotification(
            title: "邂逅成功",
            body: "你与 \(partner) 因一只漂流瓶相遇了",
            kind: .encounter
        )
        checkAchievements()
        persist()
        return conversation.id
    }

    func publishMood(content: String, mood: BottleMood) -> Bool {
        guard ContentSafety.isAllowed(content) else { return false }
        let post = MoodPost(content: content, mood: mood, authorAlias: userAlias)
        moodPosts.insert(post, at: 0)
        checkAchievements()
        persist()
        return true
    }

    func addDiaryEntry(content: String, mood: BottleMood) -> Bool {
        guard ContentSafety.isAllowed(content) else { return false }
        let entry = DiaryEntry(content: content, mood: mood)
        diaryEntries.insert(entry, at: 0)
        let today = Self.dayKey(for: Date())
        lastDiaryDate = today
        addNotification(
            title: "日记已保存",
            body: "你的心情被温柔地记录在了今夜。",
            kind: .reminder
        )
        checkAchievements()
        persist()
        return true
    }

    func saveBottle(_ bottle: DriftBottle) {
        savedBottleIDs.insert(bottle.id)
        addNotification(
            title: "已收藏漂流瓶",
            body: "这只瓶子被放进了你的瓶海记忆。",
            kind: .reminder
        )
        persist()
    }

    func unsaveBottle(_ bottle: DriftBottle) {
        savedBottleIDs.remove(bottle.id)
        persist()
    }

    func isBottleSaved(_ bottle: DriftBottle) -> Bool {
        savedBottleIDs.contains(bottle.id)
    }

    func likePost(_ post: MoodPost) {
        guard let index = moodPosts.firstIndex(of: post) else { return }
        moodPosts[index].likeCount += 1
        persist()
    }

    @discardableResult
    func sendMessage(in conversationID: UUID, content: String) -> Bool {
        guard ContentSafety.isAllowed(content) else { return false }
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return false }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = ChatMessage(content: trimmed, isFromMe: true)
        conversations[index].messages.append(message)
        conversations[index].lastMessage = trimmed
        conversations[index].lastMessageAt = Date()
        persist()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.simulateReply(at: index)
        }
        return true
    }

    func markConversationRead(_ conversationID: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].unreadCount = 0
        persist()
    }

    func markAllNotificationsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        persist()
    }

    func updateAlias(_ alias: String) {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, trimmed.count <= 12 else { return }
        userAlias = trimmed
        persist()
    }

    func updateSignature(_ signature: String) {
        userSignature = signature.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
    }

    func updateAvatarEmoji(_ emoji: String) {
        guard MockData.avatarEmojis.contains(emoji) else { return }
        profileAvatarEmoji = emoji
        persist()
    }

    func deleteDiaryEntry(_ entry: DiaryEntry) {
        diaryEntries.removeAll { $0.id == entry.id }
        persist()
    }

    func updateDiaryEntry(_ entry: DiaryEntry, content: String, mood: BottleMood) -> Bool {
        guard ContentSafety.isAllowed(content) else { return false }
        guard let index = diaryEntries.firstIndex(where: { $0.id == entry.id }) else { return false }
        diaryEntries[index].content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        diaryEntries[index].mood = mood
        persist()
        return true
    }

    func setCatchMoodFilter(_ filter: CatchMoodFilter) {
        catchMoodFilter = filter
        persist()
    }

    func addCompanionMinutes(_ minutes: Int) {
        companionMinutesTotal += minutes
        checkAchievements()
        persist()
    }

    func resetToMockData() {
        guard isLoggedIn else { return }
        caughtBottleIDs = []
        savedBottleIDs = []
        unlockedAchievements = []
        lastDiaryDate = nil
        let alias = userAlias.isEmpty ? AuthStore.suggestedAlias(for: userEmail) : userAlias
        userAlias = alias
        userSignature = ""
        apply(localSeedSnapshot(for: userEmail, alias: alias))
        persist()
    }

    private func availableBottlesForCatch() -> [DriftBottle] {
        oceanBottles.filter { bottle in
            guard bottle.authorAlias != userAlias else { return false }
            guard !caughtBottleIDs.contains(bottle.id) else { return false }
            guard !hiddenBottleIDs.contains(bottle.id) else { return false }
            guard !blockedAliases.contains(bottle.authorAlias) else { return false }
            if let mood = catchMoodFilter.bottleMood {
                return bottle.mood == mood
            }
            return true
        }
    }

    private func simulateReply(at index: Int) {
        guard conversations.indices.contains(index) else { return }

        let reply = ChatMessage(
            content: MockData.chatReplies.randomElement() ?? "谢谢你。",
            isFromMe: false
        )
        conversations[index].messages.append(reply)
        conversations[index].lastMessage = reply.content
        conversations[index].lastMessageAt = Date()
        conversations[index].unreadCount += 1
        addNotification(
            title: conversations[index].partnerAlias,
            body: reply.content,
            kind: .newMessage
        )
        persist()
    }

    private func checkAchievements() {
        let metrics: [String: Int] = [
            "first_throw": thrownBottles.isEmpty ? 0 : 1,
            "first_catch": caughtHistory.isEmpty ? 0 : 1,
            "first_encounter": conversations.isEmpty ? 0 : 1,
            "mood_voice": moodPosts.contains { $0.authorAlias == userAlias } ? 1 : 0,
            "diary_keeper": diaryEntries.isEmpty ? 0 : 1,
            "throw_5": thrownBottles.count,
            "catch_5": caughtHistory.count,
            "companion_30": companionMinutesTotal
        ]

        for achievement in MockData.achievements {
            guard !unlockedAchievements.contains(achievement.id) else { continue }
            let value = metrics[achievement.id] ?? 0
            if value >= achievement.requiredCount {
                unlockedAchievements.insert(achievement.id)
                addNotification(
                    title: "成就解锁 · \(achievement.title)",
                    body: achievement.detail,
                    kind: .encounter
                )
            }
        }
    }

    private func addNotification(title: String, body: String, kind: AppNotification.NotificationKind) {
        let notification = AppNotification(title: title, body: body, kind: kind)
        notifications.insert(notification, at: 0)
    }

    private func apply(_ snapshot: AppSnapshot) {
        if !snapshot.userEmail.isEmpty {
            userEmail = snapshot.userEmail
        }
        userAlias = snapshot.userAlias
        userSignature = snapshot.userSignature
        profileAvatarEmoji = snapshot.profileAvatarEmoji
        oceanBottles = snapshot.oceanBottles
        thrownBottles = snapshot.thrownBottles
        moodPosts = snapshot.moodPosts
        conversations = snapshot.conversations
        notifications = snapshot.notifications
        caughtBottleIDs = Set(snapshot.caughtBottleIDs)
        caughtHistory = snapshot.caughtHistory
        savedBottleIDs = Set(snapshot.savedBottleIDs)
        diaryEntries = snapshot.diaryEntries
        unlockedAchievements = Set(snapshot.unlockedAchievements)
        catchMoodFilter = snapshot.catchMoodFilter
        companionMinutesTotal = snapshot.companionMinutesTotal
        lastDiaryDate = snapshot.lastDiaryDate
        moodComments = snapshot.moodComments
        blockedAliases = Set(snapshot.blockedAliases)
        hiddenPostIDs = Set(snapshot.hiddenPostIDs)
        hiddenBottleIDs = Set(snapshot.hiddenBottleIDs)
        hiddenCommentIDs = Set(snapshot.hiddenCommentIDs)
        submittedReports = snapshot.submittedReports
    }

    private func persist() {
        guard isLoggedIn, !userEmail.isEmpty else { return }
        let snapshot = AppSnapshot(
            userEmail: userEmail,
            userAlias: userAlias,
            userSignature: userSignature,
            oceanBottles: oceanBottles,
            thrownBottles: thrownBottles,
            moodPosts: moodPosts,
            conversations: conversations,
            notifications: notifications,
            caughtBottleIDs: Array(caughtBottleIDs),
            caughtHistory: caughtHistory,
            savedBottleIDs: Array(savedBottleIDs),
            diaryEntries: diaryEntries,
            unlockedAchievements: Array(unlockedAchievements),
            catchMoodFilter: catchMoodFilter,
            companionMinutesTotal: companionMinutesTotal,
            lastDiaryDate: lastDiaryDate,
            moodComments: moodComments,
            blockedAliases: Array(blockedAliases),
            hiddenPostIDs: Array(hiddenPostIDs),
            hiddenBottleIDs: Array(hiddenBottleIDs),
            hiddenCommentIDs: Array(hiddenCommentIDs),
            profileAvatarEmoji: profileAvatarEmoji,
            submittedReports: submittedReports
        )
        LocalStore.save(snapshot, for: userEmail)
    }

    private static func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
