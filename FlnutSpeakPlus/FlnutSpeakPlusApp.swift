import SwiftUI

@main
struct FlnutSpeakPlusApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .animation(.easeInOut(duration: 0.25), value: appState.isLoggedIn)
        }
    }
}
