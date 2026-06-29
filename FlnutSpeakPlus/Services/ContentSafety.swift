import Foundation

struct MoodComment: Identifiable, Codable, Equatable {
    let id: UUID
    var postID: UUID
    var authorAlias: String
    var content: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        postID: UUID,
        authorAlias: String,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.postID = postID
        self.authorAlias = authorAlias
        self.content = content
        self.createdAt = createdAt
    }
}

enum ReportReason: String, CaseIterable, Identifiable, Codable {
    case harassment = "骚扰或欺凌"
    case sexual = "色情或低俗"
    case spam = "垃圾广告或引流"
    case illegal = "违法或有害信息"
    case hate = "仇恨或歧视"
    case other = "其他不当内容"

    var id: String { rawValue }
}

struct ContentReport: Identifiable, Codable, Equatable {
    let id: UUID
    var contentType: String
    var contentID: UUID
    var targetAlias: String?
    var reason: ReportReason
    var excerpt: String
    var reporterEmail: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        contentType: String,
        contentID: UUID,
        targetAlias: String?,
        reason: ReportReason,
        excerpt: String,
        reporterEmail: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.contentType = contentType
        self.contentID = contentID
        self.targetAlias = targetAlias
        self.reason = reason
        self.excerpt = excerpt
        self.reporterEmail = reporterEmail
        self.createdAt = createdAt
    }
}

enum AppSupport {
    static let contactEmail = "support@feiyucompanion.com"
    static let reviewResponseHours = 24
    static let privacyPolicyURL = URL(string: "https://feiyucompanion.com/privacy")!
    static let termsOfServiceURL = URL(string: "https://feiyucompanion.com/terms")!
    static let communityGuidelinesURL = URL(string: "https://feiyucompanion.com/community")!

    static func reportMailURL(for report: ContentReport) -> URL? {
        let subject = "[飞语陪伴举报] \(report.contentType) · \(report.reason.rawValue)"
        let body = """
        举报编号：\(report.id.uuidString)
        内容类型：\(report.contentType)
        内容 ID：\(report.contentID.uuidString)
        被举报用户：\(report.targetAlias ?? "匿名/未知")
        举报原因：\(report.reason.rawValue)
        内容摘要：\(report.excerpt)
        举报人邮箱：\(report.reporterEmail)
        提交时间：\(ISO8601DateFormatter().string(from: report.createdAt))

        ---
        请运营团队在 \(reviewResponseHours) 小时内处理。此邮件由 App 自动生成。
        """
        return mailtoURL(to: contactEmail, subject: subject, body: body)
    }

    static func mailtoURL(to email: String, subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}

enum ContentSafety {
    private static let blockedKeywords = [
        "色情", "裸聊", "约炮", "赌博", "刷单", "加微信", "加qq", "违法",
        "代孕", "枪支", "诈骗", "传销", "买卖", "私服", "外挂"
    ]

    static func isAllowed(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard trimmed.count <= 500 else { return false }
        let lower = trimmed.lowercased()
        return !blockedKeywords.contains { lower.contains($0) }
    }

    static var rejectionMessage: String {
        "内容包含不当信息或超出长度限制，请修改后重试。"
    }

    static func excerpt(_ text: String, limit: Int = 80) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= limit { return trimmed }
        return String(trimmed.prefix(limit)) + "…"
    }
}
