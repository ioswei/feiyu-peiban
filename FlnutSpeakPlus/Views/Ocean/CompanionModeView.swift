import SwiftUI

struct CompanionModeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMinutes = 15
    @State private var remainingSeconds = 0
    @State private var isRunning = false
    @State private var timer: Timer?

    private let options = [10, 15, 30, 45]

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AppTheme.heroGradient)
                        Text("夜航陪伴")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("不必说话，只需知道这片海洋有人陪你")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    if isRunning {
                        runningView
                    } else {
                        pickerView
                    }

                    if !isRunning {
                        GradientPrimaryButton(title: "开始陪伴", icon: "play.fill") {
                            startSession()
                        }
                        .padding(.horizontal, 20)
                    } else {
                        GlassSecondaryButton(title: "结束陪伴", icon: "stop.fill") {
                            endSession(completed: false)
                        }
                        .padding(.horizontal, 20)
                    }

                    Text("已累计陪伴 \(appState.companionMinutesTotal) 分钟")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(24)
            }
            .navigationTitle("陪伴模式")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .hidesTabBarWhenPushed()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        endSession(completed: false)
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.cyanGlow)
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
    }

    private var pickerView: some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.self) { min in
                Button {
                    selectedMinutes = min
                } label: {
                    Text("\(min) 分钟")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedMinutes == min ? AppTheme.skyBlue.opacity(0.35) : AppTheme.glassFill)
                        .foregroundStyle(AppTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                                .stroke(selectedMinutes == min ? AppTheme.cyanGlow.opacity(0.6) : AppTheme.glassBorder, lineWidth: 1)
                        )
                }
            }
        }
    }

    private var runningView: some View {
        VStack(spacing: 16) {
            Text(formattedTime)
                .font(.system(size: 52, weight: .light, design: .rounded))
                .foregroundStyle(AppTheme.heroGradient)
            Text("海洋在听，你也可以什么都不想")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
            DriftBottleIllustration(size: 80)
                .opacity(0.85)
        }
        .padding(.vertical, 20)
    }

    private var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func startSession() {
        remainingSeconds = selectedMinutes * 60
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    endSession(completed: true)
                }
            }
        }
    }

    private func endSession(completed: Bool) {
        timer?.invalidate()
        timer = nil
        if isRunning {
            let elapsed = selectedMinutes * 60 - remainingSeconds
            let minutes = max(1, elapsed / 60)
            appState.addCompanionMinutes(minutes)
        }
        isRunning = false
        if completed {
            dismiss()
        }
    }
}
