import SwiftUI

/// 漂流瓶造型 — 圆肚细颈，经典瓶形
struct DriftBottleIllustration: View {
    var size: CGFloat = 130

    var body: some View {
        ZStack {
            DriftBottleShape()
                .fill(AppTheme.abyss.opacity(0.4))
                .blur(radius: 10)
                .offset(y: size * 0.06)

            DriftBottleShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            AppTheme.cyanGlow.opacity(0.5),
                            AppTheme.skyBlue.opacity(0.8),
                            AppTheme.electricBlue.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    DriftBottleShape()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), AppTheme.cyanGlow.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: size * 0.06, height: size * 0.42)
                        .offset(x: size * 0.30, y: size * 0.08)
                }

            // 瓶内信笺
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.20, height: size * 0.26)
                .overlay {
                    VStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { _ in
                            Capsule()
                                .fill(AppTheme.skyBlue.opacity(0.3))
                                .frame(width: size * 0.12, height: 2)
                        }
                    }
                }
                .rotationEffect(.degrees(-8))
                .offset(y: size * 0.10)

            // 软木塞
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.88, green: 0.74, blue: 0.50), Color(red: 0.62, green: 0.46, blue: 0.28)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.16, height: size * 0.07)
                .offset(y: -size * 0.395)
        }
        .frame(width: size * 0.72, height: size)
        .rotationEffect(.degrees(-12))
    }
}

private struct DriftBottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.5

        let neckW = w * 0.22
        let neckTop = h * 0.02
        let neckBottom = h * 0.22
        let neckLeft = cx - neckW * 0.5

        path.move(to: CGPoint(x: neckLeft, y: neckBottom))
        path.addLine(to: CGPoint(x: neckLeft, y: neckTop))
        path.addQuadCurve(
            to: CGPoint(x: neckLeft + neckW, y: neckTop),
            control: CGPoint(x: cx, y: neckTop - h * 0.01)
        )
        path.addLine(to: CGPoint(x: neckLeft + neckW, y: neckBottom))

        path.addQuadCurve(
            to: CGPoint(x: w * 0.92, y: h * 0.52),
            control: CGPoint(x: w * 1.05, y: h * 0.28)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx, y: h * 0.98),
            control: CGPoint(x: w * 0.95, y: h * 0.95)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.08, y: h * 0.52),
            control: CGPoint(x: w * 0.05, y: h * 0.95)
        )
        path.addQuadCurve(
            to: CGPoint(x: neckLeft, y: neckBottom),
            control: CGPoint(x: -w * 0.05, y: h * 0.28)
        )
        path.closeSubpath()
        return path
    }
}

struct OceanRippleRings: View {
    var pulse: Bool

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(AppTheme.cyanGlow.opacity(0.18 - Double(ring) * 0.045), lineWidth: 1)
                    .frame(width: 90 + CGFloat(ring * 26), height: 90 + CGFloat(ring * 26))
                    .scaleEffect(pulse ? 1.04 : 0.96)
            }
        }
        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulse)
    }
}

struct OceanWaveLine: View {
    var phase: CGFloat

    var body: some View {
        WaveShape(phase: phase, amplitude: 4)
            .stroke(AppTheme.cyanGlow.opacity(0.15), lineWidth: 1.5)
            .frame(height: 20)
    }
}

private struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: rect.width, by: 2) {
            let rel = x / rect.width
            let y = midY + sin((rel * .pi * 2) + phase * 0.05) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}
