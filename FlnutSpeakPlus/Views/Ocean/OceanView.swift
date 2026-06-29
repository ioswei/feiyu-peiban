import SwiftUI

struct OceanView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showThrowSheet = false
    @State private var showCompanion = false
    @State private var caughtBottle: DriftBottle?
    @State private var isCatching = false
    @State private var floatOffset: CGFloat = 0
    @State private var glowPulse = false
    @State private var wavePhase: CGFloat = 0
    @State private var showEmptyOceanAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()

                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    dailyWhisperCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                    heroStage

                    actionPanel
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCompanion) {
                NavigationStack {
                    CompanionModeView()
                }
            }
            .sheet(isPresented: $showThrowSheet) {
                ThrowBottleView()
            }
            .sheet(item: $caughtBottle) { bottle in
                CatchBottleView(bottle: bottle)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    floatOffset = 10
                }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    wavePhase = 360
                }
            }
            .alert("海洋空空如也", isPresented: $showEmptyOceanAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                if appState.catchMoodFilter == .any {
                    Text("暂时没有新的漂流瓶了。不妨扔一个瓶子，让心事继续漂向远方。")
                } else {
                    Text("当前心情筛选下没有可捡的瓶子，试试切换「不限」或其他心情。")
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            AppBadge(text: "FEIYU · 飞语陪伴")
            GradientTitle(text: "遇见另一个灵魂", size: 28)
            SectionCaption(text: "把说不出口的心事，交给蓝色海洋\n等待一次温柔的偶遇")
        }
        .padding(.horizontal, 20)
    }

    private var dailyWhisperCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .foregroundStyle(AppTheme.cyanGlow)
            Text(appState.dailyWhisper)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                .fill(AppTheme.glassFill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                        .stroke(AppTheme.glassBorder, lineWidth: 1)
                )
        }
    }

    private var heroStage: some View {
        ZStack {
            OceanRippleRings(pulse: glowPulse)

            VStack(spacing: 10) {
                DriftBottleIllustration(size: 120)
                    .shadow(color: AppTheme.cyanGlow.opacity(glowPulse ? 0.4 : 0.18), radius: 22, y: 10)
                    .offset(y: -floatOffset)

                OceanWaveLine(phase: wavePhase)
                    .frame(maxWidth: 220)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var actionPanel: some View {
        VStack(spacing: 14) {
            moodFilterRow

            VStack(spacing: 10) {
                GradientPrimaryButton(title: "扔出漂流瓶", icon: "arrow.up.circle.fill") {
                    showThrowSheet = true
                }

                GlassSecondaryButton(title: "捡一个漂流瓶", icon: "hand.wave.fill", isLoading: isCatching) {
                    catchBottle()
                }
            }

            quickLinksRow
            statsRow
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.radiusLG, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.radiusLG, style: .continuous)
                        .fill(AppTheme.glassFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusLG, style: .continuous)
                        .stroke(AppTheme.glassBorder, lineWidth: 1)
                )
        }
    }

    private var moodFilterRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("想遇见哪种心情？")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CatchMoodFilter.allCases) { filter in
                        Button {
                            appState.setCatchMoodFilter(filter)
                        } label: {
                            HStack(spacing: 4) {
                                Text(filter.emoji)
                                Text(filter.rawValue)
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(appState.catchMoodFilter == filter ? AppTheme.skyBlue.opacity(0.35) : AppTheme.glassFill)
                            .foregroundStyle(AppTheme.textPrimary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    appState.catchMoodFilter == filter ? AppTheme.cyanGlow.opacity(0.6) : AppTheme.glassBorder,
                                    lineWidth: 1
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    private var quickLinksRow: some View {
        HStack(spacing: 10) {
            NavigationLink {
                MyBottlesView()
            } label: {
                quickLink(title: "我的瓶海", icon: "archivebox.fill")
            }
            .buttonStyle(.plain)

            Button {
                showCompanion = true
            } label: {
                quickLink(title: "夜航陪伴", icon: "moon.stars.fill")
            }
        }
    }

    private func quickLink(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.skyBlue.opacity(0.12))
        .foregroundStyle(AppTheme.cyanGlow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: appState.catchableBottleCount, label: "可捡", icon: "drop.fill")
            statDivider
            statItem(value: appState.thrownBottles.count, label: "已扔", icon: "paperplane.fill")
            statDivider
            Button {
                appState.openMessagesTab()
            } label: {
                statItem(value: appState.visibleConversations().count, label: "邂逅", icon: "heart.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(AppTheme.glassBorder)
            .frame(width: 1, height: 36)
    }

    private func statItem(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.cyanGlow)
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func catchBottle() {
        guard appState.catchableBottleCount > 0 else {
            showEmptyOceanAlert = true
            return
        }

        isCatching = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let bottle = appState.catchRandomBottle() {
                caughtBottle = bottle
            } else {
                showEmptyOceanAlert = true
            }
            isCatching = false
        }
    }
}
