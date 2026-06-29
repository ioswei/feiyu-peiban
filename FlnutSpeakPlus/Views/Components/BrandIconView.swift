import SwiftUI

struct BrandIconView: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Image("LaunchLogoGlow")
                .resizable()
                .interpolation(.high)
                .aspectRatio(1, contentMode: .fit)
                .frame(width: size * 1.22, height: size * 1.22)
                .blur(radius: size * 0.02)
                .opacity(0.92)

            Image("LaunchLogo")
                .resizable()
                .interpolation(.high)
                .aspectRatio(1, contentMode: .fit)
                .frame(width: size, height: size)
                .shadow(color: AppTheme.cyanGlow.opacity(0.22), radius: size * 0.10, y: size * 0.04)
        }
        .frame(width: size * 1.22, height: size * 1.22)
    }
}

#Preview {
    ZStack {
        AppTheme.screenGradient.ignoresSafeArea()
        BrandIconView(size: 160)
    }
    .preferredColorScheme(.dark)
}
