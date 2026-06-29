import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(red: 0.04, green: 0.08, blue: 0.20, alpha: 0.85)

        let normal = UIColor(white: 1, alpha: 0.45)
        let selected = UIColor(red: 0.35, green: 0.85, blue: 1.0, alpha: 1)
        appearance.stackedLayoutAppearance.normal.iconColor = normal
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normal]
        appearance.stackedLayoutAppearance.selected.iconColor = selected
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selected]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $appState.selectedMainTab) {
            OceanView()
                .tabItem {
                    Label("海洋", systemImage: "water.waves")
                }
                .tag(MainTab.ocean)

            MoodSquareView()
                .tabItem {
                    Label("广场", systemImage: "heart.text.square")
                }
                .tag(MainTab.square)

            MessagesView()
                .tabItem {
                    Label("消息", systemImage: "bubble.left.and.bubble.right")
                }
                .badge(appState.unreadMessageCount)
                .tag(MainTab.messages)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(MainTab.profile)
        }
        .tint(AppTheme.cyanGlow)
    }
}
