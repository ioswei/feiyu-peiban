import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showCompanion = false

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        heroSection
                        quickActionsSection
                        statsGrid
                        journeySection
                        contentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body)
                            .foregroundStyle(AppTheme.cyanGlow)
                    }
                    .accessibilityLabel("设置")
                }
            }
            .sheet(isPresented: $showCompanion) {
                NavigationStack {
                    CompanionModeView()
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                NavigationLink {
                    ProfileEditView()
                } label: {
                    VStack(spacing: 14) {
                        GradientAvatar(emoji: appState.profileAvatarEmoji, size: 96)

                        VStack(spacing: 6) {
                            Text(appState.userAlias)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            if !appState.userSignature.isEmpty {
                                Text(appState.userSignature)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        HStack(spacing: 8) {
                            AppBadge(text: appState.profileBadgeTitle)
                            if let memberSince = appState.memberSinceText {
                                AppBadge(text: "\(memberSince) 加入")
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(AppTheme.cyanGlow)
                    Text("编辑资料")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.cyanGlow)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 4)
        }
        .padding(.top, 8)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            quickActionLink(title: "写日记", icon: "book.closed.fill") {
                MoodDiaryView()
            }
            quickActionLink(title: "我的瓶海", icon: "archivebox.fill") {
                MyBottlesView()
            }
            quickActionLink(title: "成就", icon: "rosette") {
                AchievementsView()
            }
        }
    }

    private func quickActionLink<Destination: View>(
        title: String,
        icon: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            GlassCard(cornerRadius: AppTheme.radiusMD) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(AppTheme.cyanGlow)
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats

    private var statsGrid: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("我的数据")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    statChip(value: appState.thrownBottles.count, label: "扔瓶")
                    statChip(value: appState.caughtHistory.count, label: "捡瓶")
                    statChip(value: appState.visibleConversations().count, label: "邂逅")
                    statChip(value: appState.myMoodPostCount, label: "动态")
                    statChip(value: appState.diaryEntries.count, label: "日记")
                    statChip(value: appState.unlockedAchievements.count, label: "成就")
                }
            }
        }
    }

    private func statChip(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                .fill(AppTheme.skyBlue.opacity(0.12))
        }
    }

    // MARK: - Journey

    private var journeySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("海洋足迹")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    footprintItem(icon: "drop.fill", value: "\(appState.catchableBottleCount)", label: "可捡")
                    footprintItem(icon: "star.fill", value: "\(appState.savedBottleIDs.count)", label: "收藏")
                    footprintItem(icon: "moon.stars.fill", value: "\(appState.companionMinutesTotal)分", label: "陪伴")
                }

                if let mood = appState.dominantDiaryMood(), !appState.diaryEntries.isEmpty {
                    HStack(spacing: 8) {
                        Text("近期心情倾向")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("\(mood.emoji) \(mood.rawValue)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.cyanGlow)
                    }
                }

                if !appState.notifications.isEmpty {
                    Rectangle()
                        .fill(AppTheme.glassBorder)
                        .frame(height: 1)

                    Text("最近动态")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textTertiary)

                    ForEach(appState.notifications.prefix(3)) { notification in
                        Button {
                            handleNotificationTap(notification)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(AppTheme.skyBlue.opacity(0.25))
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 5)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(notification.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(notification.body)
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.textTertiary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(notification.createdAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textTertiary.opacity(0.8))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func footprintItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.cyanGlow)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                .fill(AppTheme.glassFill)
        }
    }

    // MARK: - Sections

    private var contentSection: some View {
        sectionCard(title: "我的内容") {
            featureLink(title: "心情日记", subtitle: streakSubtitle, icon: "book.closed.fill") {
                MoodDiaryView()
            }
            divider
            featureLink(title: "我的瓶海", subtitle: "扔出、捡过与收藏的瓶子", icon: "archivebox.fill") {
                MyBottlesView()
            }
            divider
            featureLink(title: "成就徽章", subtitle: achievementSubtitle, icon: "rosette") {
                AchievementsView()
            }
            divider
            companionRow
        }
    }

    private var companionRow: some View {
        Button {
            showCompanion = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "moon.stars.fill")
                    .font(.body)
                    .foregroundStyle(AppTheme.cyanGlow)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("夜航陪伴")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("累计 \(appState.companionMinutesTotal) 分钟")
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

    private func handleNotificationTap(_ notification: AppNotification) {
        switch notification.kind {
        case .newMessage, .encounter:
            if let conversation = appState.conversations.first(where: { $0.partnerAlias == notification.title }) {
                appState.openMessagesTab(conversationID: conversation.id)
            } else {
                appState.openMessagesTab(showNotifications: true)
            }
        case .bottleCaught:
            appState.openOceanTab()
        case .reminder:
            appState.openMessagesTab(showNotifications: true)
        }
    }

    // MARK: - Helpers

    private var streakSubtitle: String {
        if appState.diaryStreakDays > 0 {
            return "连续记录 \(appState.diaryStreakDays) 天 · 仅自己可见"
        }
        return "仅自己可见的私密记录"
    }

    private var achievementSubtitle: String {
        let progress = appState.achievementProgress
        return "已解锁 \(progress.unlocked)/\(progress.total) 枚徽章"
    }

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
