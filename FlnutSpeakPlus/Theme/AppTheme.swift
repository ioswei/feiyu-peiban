import SwiftUI

enum AppTheme {
    // MARK: - Blue Gradient Palette
    static let abyss = Color(red: 0.04, green: 0.06, blue: 0.18)
    static let deepBlue = Color(red: 0.06, green: 0.12, blue: 0.32)
    static let oceanBlue = Color(red: 0.10, green: 0.28, blue: 0.58)
    static let skyBlue = Color(red: 0.22, green: 0.52, blue: 0.92)
    static let cyanGlow = Color(red: 0.35, green: 0.85, blue: 1.0)
    static let periwinkle = Color(red: 0.55, green: 0.65, blue: 1.0)
    static let electricBlue = Color(red: 0.20, green: 0.55, blue: 1.0)

    static let textPrimary = Color(red: 0.94, green: 0.97, blue: 1.0)
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)

    static let glassFill = Color.white.opacity(0.07)
    static let glassBorder = Color.white.opacity(0.18)
    static let glassHighlight = Color.white.opacity(0.28)

    // MARK: - Gradients
    static let screenGradient = LinearGradient(
        colors: [abyss, deepBlue, Color(red: 0.08, green: 0.22, blue: 0.48)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [cyanGlow, skyBlue, periwinkle],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonGradient = LinearGradient(
        colors: [Color(red: 0.30, green: 0.75, blue: 1.0), electricBlue, Color(red: 0.40, green: 0.45, blue: 0.98)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cardShine = LinearGradient(
        colors: [glassHighlight.opacity(0.35), Color.clear, cyanGlow.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let avatarGradient = LinearGradient(
        colors: [cyanGlow.opacity(0.9), skyBlue, periwinkle.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let bubbleMine = LinearGradient(
        colors: [Color(red: 0.35, green: 0.78, blue: 1.0), electricBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Legacy aliases
    static let moonGlow = textPrimary
    static let warmAccent = cyanGlow
    static let oceanDeep = abyss
    static let oceanMid = deepBlue
    static let oceanLight = skyBlue
    static let cardBackground = glassFill
    static let cardBorder = glassBorder
    static let oceanGradient = screenGradient
    static let glowGradient = avatarGradient

    // MARK: - Layout
    static let radiusSM: CGFloat = 12
    static let radiusMD: CGFloat = 18
    static let radiusLG: CGFloat = 24
    static let radiusXL: CGFloat = 32
}

// MARK: - Background

struct OceanBackground: View {
    var body: some View {
        ZStack {
            AppTheme.screenGradient
                .ignoresSafeArea()

            // 顶部柔光（静态，不参与布局）
            RadialGradient(
                colors: [AppTheme.cyanGlow.opacity(0.14), AppTheme.skyBlue.opacity(0.05), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea()

            // 中部微光，突出漂流瓶区域
            RadialGradient(
                colors: [AppTheme.periwinkle.opacity(0.10), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 260
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Cards

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = AppTheme.radiusMD
    let content: Content

    init(cornerRadius: CGFloat = AppTheme.radiusMD, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(AppTheme.glassFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.glassHighlight, AppTheme.glassBorder.opacity(0.5), AppTheme.cyanGlow.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(AppTheme.cardShine)
                            .allowsHitTesting(false)
                    )
            }
    }
}

// MARK: - Buttons

struct GradientPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background {
                if isEnabled {
                    RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                        .fill(AppTheme.buttonGradient)
                        .shadow(color: AppTheme.cyanGlow.opacity(0.35), radius: 16, y: 8)
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                }
            }
            .foregroundStyle(isEnabled ? Color.white : AppTheme.textTertiary)
        }
        .disabled(!isEnabled)
    }
}

struct GlassSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(AppTheme.cyanGlow)
                } else {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .font(.body.weight(.medium))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                            .fill(AppTheme.glassFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                            .stroke(AppTheme.glassBorder, lineWidth: 1)
                    )
            }
            .foregroundStyle(AppTheme.textPrimary)
        }
        .disabled(isLoading)
    }
}

// MARK: - Typography

struct GradientTitle: View {
    let text: String
    var size: CGFloat = 34

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.heroGradient)
    }
}

struct SectionCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
    }
}

// MARK: - Chips & Stats

struct MoodChip: View {
    let mood: BottleMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.title3)
                Text(mood.rawValue)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                    .fill(isSelected ? AppTheme.skyBlue.opacity(0.35) : AppTheme.glassFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                            .stroke(
                                isSelected ? AppTheme.cyanGlow.opacity(0.7) : AppTheme.glassBorder,
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                    .shadow(color: isSelected ? AppTheme.cyanGlow.opacity(0.2) : .clear, radius: 8)
            }
            .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
            .scaleEffect(isSelected ? 1.02 : 1)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let icon: String
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            Image(systemName: icon)
                .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                .foregroundStyle(AppTheme.cyanGlow)
                .frame(width: compact ? 28 : 36, height: compact ? 28 : 36)
                .background(Circle().fill(AppTheme.skyBlue.opacity(0.2)))

            Text(value)
                .font(.system(size: compact ? 20 : 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text(title)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 10 : 14)
        .padding(.horizontal, compact ? 2 : 8)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                        .fill(AppTheme.glassFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                        .stroke(AppTheme.glassBorder, lineWidth: 1)
                )
        }
    }
}

struct PageSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GradientAvatar: View {
    var emoji: String = "🌊"
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.avatarGradient)
                .frame(width: size, height: size)
                .shadow(color: AppTheme.cyanGlow.opacity(0.4), radius: 20, y: 6)

            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 2)
                .frame(width: size - 4, height: size - 4)

            Text(emoji)
                .font(.system(size: size * 0.42))
        }
    }
}

struct AppBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(AppTheme.cyanGlow)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(AppTheme.cyanGlow.opacity(0.12))
                    .overlay(Capsule().stroke(AppTheme.cyanGlow.opacity(0.35), lineWidth: 1))
            }
    }
}

// MARK: - View Modifiers

struct AppNavigationStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct AppTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                    .fill(AppTheme.glassFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                            .stroke(AppTheme.glassBorder, lineWidth: 1)
                    )
            }
            .foregroundStyle(AppTheme.textPrimary)
            .font(.body)
    }
}

extension View {
    func appNavigationStyle() -> some View {
        modifier(AppNavigationStyle())
    }

    func appTextEditorStyle() -> some View {
        modifier(AppTextEditorStyle())
    }

    /// 进入二级页面时隐藏底部 TabBar
    func hidesTabBarWhenPushed() -> some View {
        toolbar(.hidden, for: .tabBar)
    }
}
