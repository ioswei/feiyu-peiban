import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.9
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var rippleScale: CGFloat = 0.92
    @State private var rippleOpacity: Double = 0.5

    var body: some View {
        LaunchScreenContent(
            logoScale: logoScale,
            logoOpacity: logoOpacity,
            titleOpacity: titleOpacity,
            subtitleOpacity: subtitleOpacity,
            rippleScale: rippleScale,
            rippleOpacity: rippleOpacity,
            animateRipple: true
        )
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                logoScale = 1
                logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.12)) {
                titleOpacity = 1
                subtitleOpacity = 1
            }
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: true)) {
                rippleScale = 1.06
                rippleOpacity = 0.12
            }
        }
    }
}
