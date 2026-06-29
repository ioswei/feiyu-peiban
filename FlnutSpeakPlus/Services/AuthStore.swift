import Foundation

struct AuthAccount: Codable, Equatable {
    let email: String
    let createdAt: Date
}

struct PendingVerification: Codable, Equatable {
    let email: String
    let code: String
    let sentAt: Date
    let expiresAt: Date
}

enum AuthOutcome: Equatable {
    case success(isNewUser: Bool)
    case invalidEmail
    case invalidCode
    case codeExpired
    case codeNotRequested
}

enum SendCodeOutcome: Equatable {
    case sent(displayHint: String?)
    case invalidEmail
    case tooFrequent(remainingSeconds: Int)
}

enum AuthStore {
    static let builtInDemoEmail = "abc123@yueli.com"
    static let builtInDemoCode = "123456"

    private static let accountsKey = "feiyu.auth.accounts"
    private static let sessionKey = "feiyu.auth.session"
    private static let lastLoggedInEmailKey = "feiyu.auth.lastLoggedInEmail"
    private static let pendingCodeKey = "feiyu.auth.pendingCode"
    private static let lastSendAtKey = "feiyu.auth.lastSendAt"

    private static let codeLifetime: TimeInterval = 5 * 60
    private static let resendCooldown: TimeInterval = 60

    static var currentSessionEmail: String? {
        guard let email = UserDefaults.standard.string(forKey: sessionKey) else { return nil }
        let normalized = normalizeEmail(email)
        return normalized.isEmpty ? nil : normalized
    }

    static var lastLoggedInEmail: String? {
        guard let email = UserDefaults.standard.string(forKey: lastLoggedInEmailKey) else { return nil }
        let normalized = normalizeEmail(email)
        return normalized.isEmpty ? nil : normalized
    }

    static func setSession(_ email: String) {
        let normalized = normalizeEmail(email)
        UserDefaults.standard.set(normalized, forKey: sessionKey)
        UserDefaults.standard.set(normalized, forKey: lastLoggedInEmailKey)
    }

    static func clearSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    /// 兼容旧版本：已有登录会话但未记录上次邮箱时补写。
    static func backfillLastLoggedInEmailIfNeeded() {
        guard lastLoggedInEmail == nil, let email = currentSessionEmail else { return }
        UserDefaults.standard.set(email, forKey: lastLoggedInEmailKey)
    }

    static func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isValidEmail(_ email: String) -> Bool {
        let normalized = normalizeEmail(email)
        guard normalized.count >= 5, normalized.count <= 254 else { return false }
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return normalized.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    static func isBuiltInDemoEmail(_ email: String) -> Bool {
        normalizeEmail(email) == builtInDemoEmail
    }

    static func suggestedAlias(for email: String) -> String {
        if isBuiltInDemoEmail(email) {
            return "夜航者"
        }
        let localPart = normalizeEmail(email).components(separatedBy: "@").first ?? ""
        let cleaned = localPart
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "+", with: "")
        if cleaned.count >= 2, cleaned.count <= 12 {
            return cleaned
        }
        return LocalStore.makeFirstLaunchAlias()
    }

    static func resendCooldownRemaining(for email: String) -> Int {
        let normalized = normalizeEmail(email)
        guard let lastSend = lastSendDates()[normalized] else { return 0 }
        let elapsed = Date().timeIntervalSince(lastSend)
        let remaining = Int(ceil(resendCooldown - elapsed))
        return max(0, remaining)
    }

    static func sendVerificationCode(to email: String) -> SendCodeOutcome {
        guard isValidEmail(email) else { return .invalidEmail }

        let normalized = normalizeEmail(email)
        let remaining = resendCooldownRemaining(for: normalized)
        guard remaining == 0 else { return .tooFrequent(remainingSeconds: remaining) }

        let code: String
        let hint: String?

        if isBuiltInDemoEmail(normalized) {
            code = builtInDemoCode
            hint = "验证码已发送至你的邮箱，请查收。"
        } else {
            code = String(format: "%06d", Int.random(in: 0...999_999))
            hint = "验证码已发送至你的邮箱，请查收（如未收到请检查垃圾箱）。"
        }

        let pending = PendingVerification(
            email: normalized,
            code: code,
            sentAt: Date(),
            expiresAt: Date().addingTimeInterval(codeLifetime)
        )
        savePendingVerification(pending)
        recordSendTime(for: normalized)

        return .sent(displayHint: hint)
    }

    static func loginOrRegister(email: String, verificationCode: String) -> AuthOutcome {
        guard isValidEmail(email) else { return .invalidEmail }

        let normalized = normalizeEmail(email)
        let code = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count == 6, code.allSatisfy(\.isNumber) else { return .invalidCode }

        if isBuiltInDemoEmail(normalized) {
            guard code == builtInDemoCode else { return .invalidCode }
        } else if let pending = loadPendingVerification(), pending.email == normalized {
            guard pending.code == code else { return .invalidCode }
            guard pending.expiresAt > Date() else { return .codeExpired }
        } else {
            return .codeNotRequested
        }

        var accounts = loadAccounts()
        let isNewUser = !accounts.contains { $0.email == normalized }
        if isNewUser {
            accounts.append(AuthAccount(email: normalized, createdAt: Date()))
            saveAccounts(accounts)
        }

        clearPendingVerification()
        return .success(isNewUser: isNewUser)
    }

    static func accountCreatedAt(for email: String) -> Date? {
        let normalized = normalizeEmail(email)
        return loadAccounts().first { $0.email == normalized }?.createdAt
    }

    static func deleteAccount(email: String) {
        let normalized = normalizeEmail(email)
        var accounts = loadAccounts()
        accounts.removeAll { $0.email == normalized }
        saveAccounts(accounts)
        if currentSessionEmail == normalized {
            clearSession()
        }
        if lastLoggedInEmail == normalized {
            UserDefaults.standard.removeObject(forKey: lastLoggedInEmailKey)
        }
    }

    static func accountExists(_ email: String) -> Bool {
        let normalized = normalizeEmail(email)
        return loadAccounts().contains { $0.email == normalized }
    }

    static func ensureBuiltInDemoAccountRegistered() {
        var accounts = loadAccounts()
        if !accounts.contains(where: { $0.email == builtInDemoEmail }) {
            accounts.append(AuthAccount(
                email: builtInDemoEmail,
                createdAt: Date().addingTimeInterval(-30 * 24 * 3600)
            ))
            saveAccounts(accounts)
        }
        if LocalStore.load(for: builtInDemoEmail) == nil {
            LocalStore.save(MockData.makeRichLocalSnapshot(userAlias: "夜航者"), for: builtInDemoEmail)
        }
    }

    private static func loadAccounts() -> [AuthAccount] {
        guard let data = UserDefaults.standard.data(forKey: accountsKey) else { return [] }
        if let accounts = try? JSONDecoder().decode([AuthAccount].self, from: data) {
            return accounts
        }
        return []
    }

    private static func saveAccounts(_ accounts: [AuthAccount]) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        UserDefaults.standard.set(data, forKey: accountsKey)
    }

    private static func loadPendingVerification() -> PendingVerification? {
        guard let data = UserDefaults.standard.data(forKey: pendingCodeKey) else { return nil }
        return try? JSONDecoder().decode(PendingVerification.self, from: data)
    }

    private static func savePendingVerification(_ pending: PendingVerification) {
        guard let data = try? JSONEncoder().encode(pending) else { return }
        UserDefaults.standard.set(data, forKey: pendingCodeKey)
    }

    private static func clearPendingVerification() {
        UserDefaults.standard.removeObject(forKey: pendingCodeKey)
    }

    private static func lastSendDates() -> [String: Date] {
        guard let data = UserDefaults.standard.data(forKey: lastSendAtKey) else { return [:] }
        return (try? JSONDecoder().decode([String: Date].self, from: data)) ?? [:]
    }

    private static func recordSendTime(for email: String) {
        var dates = lastSendDates()
        dates[email] = Date()
        guard let data = try? JSONEncoder().encode(dates) else { return }
        UserDefaults.standard.set(data, forKey: lastSendAtKey)
    }
}
