import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if appState.isLoggedIn {
                    MainTabView()
                } else {
                    EmailLoginView()
                }
            }
            .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.45), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
                showSplash = false
            }
        }
    }
}
