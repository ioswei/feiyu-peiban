import SwiftUI

struct CatchBottleView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let bottle: DriftBottle
    @State private var showEncounterConfirm = false
    @State private var showReportSheet = false
    @State private var revealContent = false

    private var authorAlias: String {
        bottle.isAnonymous ? "匿名旅人" : bottle.authorAlias
    }

    private var canReport: Bool {
        if !bottle.isAnonymous, bottle.authorAlias == appState.userAlias { return false }
        return true
    }

    private var canBlock: Bool {
        !bottle.isAnonymous && bottle.authorAlias != appState.userAlias
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()

                ScrollView {
                    VStack(spacing: 28) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.cyanGlow.opacity(0.12))
                                .frame(width: 100, height: 100)
                                .blur(radius: 20)
                            Text("🫧")
                                .font(.system(size: 56))
                        }

                        VStack(spacing: 8) {
                            Text("你捡到了一个漂流瓶")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("来自 \(authorAlias) 的心事")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.skyBlue.opacity(0.25))
                                            .frame(width: 52, height: 52)
                                        Text(bottle.mood.emoji)
                                            .font(.title2)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(authorAlias)
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.textPrimary)
                                        HStack(spacing: 6) {
                                            Text(bottle.mood.rawValue)
                                            Text("·")
                                            Text(bottle.createdAt, style: .relative)
                                        }
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textTertiary)
                                    }
                                    Spacer()
                                }

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.cyanGlow.opacity(0.5), AppTheme.glassBorder, .clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 1)

                                Text(bottle.content)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
                                    .lineSpacing(8)
                                    .opacity(revealContent ? 1 : 0)
                                    .offset(y: revealContent ? 0 : 12)
                            }
                        }

                        VStack(spacing: 14) {
                            GradientPrimaryButton(title: "回应 Ta，开始邂逅", icon: "heart.fill") {
                                showEncounterConfirm = true
                            }

                            if !appState.isBottleSaved(bottle) {
                                GlassSecondaryButton(
                                    title: "收藏这只瓶子",
                                    icon: "star.fill"
                                ) {
                                    appState.saveBottle(bottle)
                                }
                            } else {
                                Label("已收藏到瓶海", systemImage: "star.fill")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.cyanGlow)
                            }

                            Button("轻轻放回海里") {
                                dismiss()
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                    .padding(22)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .hidesTabBarWhenPushed()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(AppTheme.cyanGlow)
                }
                if canReport {
                    ToolbarItem(placement: .primaryAction) {
                        if canBlock {
                            UserSafetyMenu(
                                targetAlias: bottle.authorAlias,
                                reportTitle: "举报漂流瓶",
                                onReport: { showReportSheet = true },
                                dismissOnBlock: true
                            )
                        } else {
                            AnonymousReportMenu(
                                reportTitle: "举报漂流瓶",
                                onReport: { showReportSheet = true }
                            )
                        }
                    }
                }
            }
            .reportReasonSheet(isPresented: $showReportSheet, title: "举报漂流瓶") { reason in
                appState.reportBottle(bottle, reason: reason)
                dismiss()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                    revealContent = true
                }
            }
            .confirmationDialog("与这位灵魂开始对话？", isPresented: $showEncounterConfirm, titleVisibility: .visible) {
                Button("开始邂逅") {
                    let conversationID = appState.startEncounter(from: bottle)
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        appState.openMessagesTab(conversationID: conversationID)
                    }
                }
                Button("再想想", role: .cancel) {}
            } message: {
                Text("每一次回应，都是两个孤独灵魂的偶遇。")
            }
        }
    }
}
