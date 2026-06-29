import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showDeleteAccountConfirm = false

    var body: some View {
        ZStack {
            OceanBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    accountSection
                    accountActionsSection
                    legalSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
        .confirmationDialog("确定删除账号？", isPresented: $showDeleteAccountConfirm, titleVisibility: .visible) {
            Button("删除账号与全部数据", role: .destructive) {
                appState.deleteAccount()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作不可恢复，将清除本设备上的所有漂流瓶、日记与聊天记录。")
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        sectionCard(title: "账号与安全") {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(AppTheme.cyanGlow)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.userEmail)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("验证码登录 · 数据仅存本设备")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
            }
            .padding(.vertical, 8)

            divider

            featureLink(title: "屏蔽管理", subtitle: "已屏蔽 \(appState.blockedUsers.count) 人", icon: "hand.raised.fill") {
                BlockedUsersView()
            }
        }
    }

    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            Button {
                appState.logout()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.body.weight(.medium))
                    Text("退出登录")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background {
                    RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                                .fill(AppTheme.glassFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                                .stroke(AppTheme.glassBorder, lineWidth: 1)
                        )
                }
            }
            .buttonStyle(.plain)

            Button {
                showDeleteAccountConfirm = true
            } label: {
                Text("删除账号")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(red: 0.92, green: 0.48, blue: 0.52))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
        .padding(.leading, 4)
    }

    private var legalSection: some View {
        sectionCard(title: "法律与支持") {
            featureLink(title: "隐私政策", subtitle: "了解数据如何被使用与保护", icon: "lock.shield.fill") {
                PrivacyPolicyView()
            }
            divider
            featureLink(title: "用户协议", subtitle: "使用服务前请仔细阅读", icon: "doc.plaintext.fill") {
                TermsOfServiceView()
            }
            divider
            featureLink(title: "社区规范", subtitle: "举报、屏蔽与内容安全说明", icon: "shield.lefthalf.filled") {
                CommunityGuidelinesView()
            }
            divider
            Link(destination: URL(string: "mailto:\(AppSupport.contactEmail)")!) {
                HStack(spacing: 14) {
                    Image(systemName: "envelope.fill")
                        .font(.body)
                        .foregroundStyle(AppTheme.cyanGlow)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("联系支持")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(AppSupport.contactEmail)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(.vertical, 10)
            }
        }
    }

    private var aboutSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("飞语陪伴")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("v1.0")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Text("把说不出口的心情装进漂流瓶，漂向大海；在广场找到同频的人，在邂逅里慢慢靠近。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Helpers

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.leading, 4)

            GlassCard {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.glassBorder)
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    private func featureLink<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppTheme.cyanGlow)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
