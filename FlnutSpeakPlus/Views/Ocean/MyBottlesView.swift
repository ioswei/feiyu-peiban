import SwiftUI

enum BottleArchiveTab: String, CaseIterable, Identifiable {
    case thrown = "我扔的"
    case caught = "我捡的"
    case saved = "收藏的"

    var id: String { rawValue }
}

struct MyBottlesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var tab: BottleArchiveTab = .thrown
    @State private var reportingBottle: DriftBottle?

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                tabPicker
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                if items.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(items, id: \.id) { item in
                                bottleCard(item)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle("我的瓶海")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
        .sheet(item: $reportingBottle) { bottle in
            ReportReasonSheet(title: "举报漂流瓶") { reason in
                appState.reportBottle(bottle, reason: reason)
                reportingBottle = nil
            }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 8) {
            ForEach(BottleArchiveTab.allCases) { t in
                Button {
                    tab = t
                } label: {
                    Text(t.rawValue)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(tab == t ? AppTheme.skyBlue.opacity(0.35) : AppTheme.glassFill)
                        .foregroundStyle(AppTheme.textPrimary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var items: [DriftBottle] {
        switch tab {
        case .thrown: appState.thrownBottles
        case .caught: appState.caughtHistory.map(\.bottle)
        case .saved: appState.savedBottles
        }
    }

    private func bottleCard(_ bottle: DriftBottle) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(bottle.mood.emoji)
                    Text(bottle.mood.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.cyanGlow)
                    Spacer()
                    if tab != .thrown, !bottle.isAnonymous {
                        Text(bottle.authorAlias)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Text(bottle.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Text(bottle.content)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
                    .lineSpacing(4)
                if tab == .caught || tab == .saved {
                    HStack {
                        if appState.isBottleSaved(bottle) {
                            Label("已收藏", systemImage: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.cyanGlow)
                        }
                        Spacer()
                        if tab == .caught {
                            Button(appState.isBottleSaved(bottle) ? "取消收藏" : "收藏") {
                                if appState.isBottleSaved(bottle) {
                                    appState.unsaveBottle(bottle)
                                } else {
                                    appState.saveBottle(bottle)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.cyanGlow)
                        }
                    }
                }
            }
        }
        .contextMenu {
            if tab != .thrown, canReport(bottle) {
                Button {
                    reportingBottle = bottle
                } label: {
                    Label("举报漂流瓶", systemImage: "exclamationmark.bubble")
                }
                if !bottle.isAnonymous, bottle.authorAlias != appState.userAlias {
                    Button(role: .destructive) {
                        appState.blockUser(bottle.authorAlias)
                    } label: {
                        Label("屏蔽作者", systemImage: "hand.raised")
                    }
                }
            }
        }
    }

    private func canReport(_ bottle: DriftBottle) -> Bool {
        if !bottle.isAnonymous, bottle.authorAlias == appState.userAlias { return false }
        return true
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            DriftBottleIllustration(size: 64)
            Text("这里还没有瓶子")
                .foregroundStyle(AppTheme.textSecondary)
            Text("去海洋扔一个或捡一个吧")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)

            Button {
                appState.openOceanTab()
            } label: {
                Text("去海洋看看")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.cyanGlow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.skyBlue.opacity(0.18))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }
}
