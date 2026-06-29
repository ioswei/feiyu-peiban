import SwiftUI

// MARK: - 隐私政策

struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocumentScaffold(title: "隐私政策") {
            legalSection(title: "我们收集的信息", text: """
                • 账号信息：你注册时提供的邮箱地址，用于登录与账号识别。
                • 用户内容：你发布的漂流瓶、心情动态、评论、日记与聊天消息（日记默认仅本地可见）。
                • 使用数据：功能使用统计、成就进度等，用于改善产品体验。
                """)
            legalSection(title: "信息如何使用", text: """
                • 提供核心功能：漂流、广场、邂逅聊天与陪伴模式。
                • 安全与合规：过滤违规内容、处理举报、执行社区规范。
                • 不会出售你的个人信息给第三方。
                """)
            legalSection(title: "数据存储", text: """
                当前版本数据主要存储在你的设备本地。正式联网版本将加密传输并存储于服务器，届时本政策会更新说明。
                """)
            legalSection(title: "你的权利", text: """
                • 在「我的」页修改昵称与签名。
                • 屏蔽或举报不当用户与内容。
                • 退出登录或删除账号（删除后本地数据不可恢复）。
                • 通过 \(AppSupport.contactEmail) 联系我们行使数据相关权利。
                """)
            legalSection(title: "未成年人", text: """
                本产品面向 17 岁及以上用户。登录时须确认年龄。我们不会故意收集未成年人个人信息。如发现请通过支持邮箱联系我们删除。
                """)
            legalWebLink(title: "在线隐私政策", url: AppSupport.privacyPolicyURL)
            Spacer(minLength: 12)
            legalContactFooter
        }
    }
}

// MARK: - 用户协议

struct TermsOfServiceView: View {
    var body: some View {
        LegalDocumentScaffold(title: "用户协议") {
            legalSection(title: "服务说明", text: """
                「飞语陪伴」是一款情绪陪伴与慢社交产品。你可以通过漂流瓶、心情广场与他人建立有限度的匿名连接。
                """)
            legalSection(title: "你的承诺", text: """
                • 不发布色情、暴力、骚扰、仇恨、欺诈或违法内容。
                • 不索要他人线下联系方式用于骚扰或引流。
                • 尊重他人匿名身份，不进行恶意人肉或威胁。
                """)
            legalSection(title: "内容与审核", text: """
                用户生成内容需遵守社区规范。我们有权过滤、隐藏或删除违规内容，并暂停或终止违规账号。
                举报将在 \(AppSupport.reviewResponseHours) 小时内受理处理。
                """)
            legalSection(title: "免责声明", text: """
                本产品不提供心理咨询或医疗诊断。若你处于心理危机，请寻求专业机构或紧急热线帮助。
                因用户间互动产生的纠纷，请在举报/屏蔽后联系我们协助处理。
                """)
            legalSection(title: "账号", text: """
                你应对账号下的行为负责。请勿共享验证码。我们支持退出登录与删除账号。
                """)
            legalWebLink(title: "在线用户协议", url: AppSupport.termsOfServiceURL)
            Spacer(minLength: 12)
            legalContactFooter
        }
    }
}

// MARK: - 屏蔽管理

struct BlockedUsersView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            OceanBackground()

            if appState.blockedUsers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.slash")
                        .font(.largeTitle)
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("暂无屏蔽用户")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("屏蔽后，对方的瓶子、动态与聊天将不再显示。")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(appState.blockedUsers, id: \.self) { alias in
                            GlassCard(cornerRadius: AppTheme.radiusMD) {
                                HStack {
                                    Circle()
                                        .fill(AppTheme.skyBlue.opacity(0.25))
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            Text(String(alias.prefix(1)))
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(AppTheme.cyanGlow)
                                        }
                                    Text(alias)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    Button("取消屏蔽") {
                                        appState.unblockUser(alias)
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.cyanGlow)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("屏蔽管理")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
    }
}

// MARK: - 共享布局

private struct LegalDocumentScaffold<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OceanBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        content
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 12))
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .topLeading)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
    }
}

@ViewBuilder
private func legalSection(title: String, text: String) -> some View {
    GlassCard {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private var legalContactFooter: some View {
    GlassCard {
        VStack(alignment: .leading, spacing: 10) {
            Text("联系我们")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("隐私、安全、举报或账号问题，请邮件联系：")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
            Link(destination: URL(string: "mailto:\(AppSupport.contactEmail)")!) {
                Label(AppSupport.contactEmail, systemImage: "envelope.fill")
                    .font(.subheadline.weight(.medium))
            }
            Text("举报提交后，App 会打开邮件并附带内容编号，便于我们在 \(AppSupport.reviewResponseHours) 小时内处理。")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@ViewBuilder
private func legalWebLink(title: String, url: URL) -> some View {
    GlassCard {
        Link(destination: url) {
            HStack {
                Label(title, systemImage: "safari")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
            }
        }
    }
}
