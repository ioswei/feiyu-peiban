import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var appState: AppState

    private var progress: (unlocked: Int, total: Int) {
        appState.achievementProgress
    }

    var body: some View {
        ZStack {
            OceanBackground()

            ScrollView {
                VStack(spacing: 16) {
                    summaryHeader

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(MockData.achievements) { achievement in
                            achievementCard(achievement)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("成就徽章")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
    }

    private var summaryHeader: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("解锁进度")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("\(progress.unlocked) / \(progress.total)")
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(AppTheme.glassBorder, lineWidth: 4)
                            .frame(width: 56, height: 56)
                        Circle()
                            .trim(from: 0, to: progressFraction)
                            .stroke(AppTheme.cyanGlow, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(progressFraction * 100))%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.cyanGlow)
                    }
                }

                ProgressView(value: progressFraction)
                    .tint(AppTheme.cyanGlow)

                Text("继续扔瓶、捡瓶、写日记与陪伴，解锁更多海洋徽章。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineSpacing(3)
            }
        }
    }

    private var progressFraction: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.unlocked) / Double(progress.total)
    }

    private func achievementCard(_ achievement: Achievement) -> some View {
        let unlocked = appState.unlockedAchievements.contains(achievement.id)
        let current = appState.achievementMetric(for: achievement)
        let fraction = appState.achievementProgressFraction(for: achievement)

        return GlassCard {
            VStack(spacing: 10) {
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(unlocked ? AppTheme.cyanGlow : AppTheme.textTertiary.opacity(0.5))

                Text(achievement.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textTertiary)

                Text(achievement.detail)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if unlocked {
                    Text("已解锁")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppTheme.cyanGlow)
                } else {
                    VStack(spacing: 4) {
                        ProgressView(value: fraction)
                            .tint(AppTheme.skyBlue)
                        Text("\(min(current, achievement.requiredCount))/\(achievement.requiredCount)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 130)
        }
    }
}
