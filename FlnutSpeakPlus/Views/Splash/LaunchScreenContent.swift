import SwiftUI

/// 启动页内容（与 LaunchScreen.storyboard 层级一致，自适应各机型安全区）
struct LaunchScreenContent: View {
    var logoScale: CGFloat = 1
    var logoOpacity: Double = 1
    var titleOpacity: Double = 1
    var subtitleOpacity: Double = 1
    var rippleScale: CGFloat = 1
    var rippleOpacity: Double = 0.35
    var animateRipple: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let safe = geometry.safeAreaInsets
            let contentHeight = geometry.size.height - safe.top - safe.bottom
            let logoSize = min(132, max(104, geometry.size.width * 0.30))

            ZStack {
                launchBackground

                // 底部微光粒子，填充大屏空白
                launchParticles(in: geometry.size)
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    Spacer(minLength: max(24, contentHeight * 0.16))

                    logoBlock(size: logoSize)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    titleBlock
                        .padding(.top, logoSize * 0.22)

                    Spacer(minLength: max(32, contentHeight * 0.22))
                }
                .padding(.horizontal, 28)
                .padding(.top, safe.top)
                .padding(.bottom, safe.bottom)
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }

    private var launchBackground: some View {
        ZStack {
            Image("LaunchBackdrop")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // SwiftUI 层叠光晕，与动态启动页衔接更自然
            RadialGradient(
                colors: [AppTheme.cyanGlow.opacity(0.10), .clear],
                center: UnitPoint(x: 0.5, y: 0.26),
                startRadius: 8,
                endRadius: 320
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, AppTheme.abyss.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private func launchParticles(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(AppTheme.cyanGlow.opacity(0.10 + Double(index % 3) * 0.04))
                    .frame(width: CGFloat(4 + index % 4), height: CGFloat(4 + index % 4))
                    .blur(radius: 1)
                    .position(
                        x: size.width * [0.15, 0.28, 0.42, 0.58, 0.72, 0.86, 0.22, 0.64, 0.48, 0.80][index],
                        y: size.height * [0.78, 0.84, 0.80, 0.88, 0.82, 0.86, 0.90, 0.76, 0.92, 0.81][index]
                    )
            }
        }
    }

    private func logoBlock(size: CGFloat) -> some View {
        ZStack {
            if animateRipple {
                Circle()
                    .stroke(AppTheme.cyanGlow.opacity(rippleOpacity * 0.28), lineWidth: 1)
                    .frame(width: size * 1.24, height: size * 1.24)
                    .scaleEffect(rippleScale)
            }

            BrandIconView(size: size)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 10) {
            Text("飞语陪伴")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .minimumScaleFactor(0.85)
                .lineLimit(1)
                .opacity(titleOpacity)

            Text("把心情漂向懂你的人")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.9)
                .lineLimit(2)
                .opacity(subtitleOpacity)
        }
        .frame(maxWidth: .infinity)
    }
}
