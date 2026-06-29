import SwiftUI

struct ProfileEditView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var alias: String = ""
    @State private var signature: String = ""
    @State private var selectedEmoji: String = "🌊"

    private let emojiColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        ZStack {
            OceanBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    avatarPreview
                    emojiPicker
                    aliasField
                    signatureField
                    saveButton
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("编辑资料")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
        .onAppear {
            alias = appState.userAlias
            signature = appState.userSignature
            selectedEmoji = appState.profileAvatarEmoji
        }
    }

    private var avatarPreview: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                GradientAvatar(emoji: selectedEmoji, size: 88)
                Text("选择代表你的海洋符号")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
        }
    }

    private var emojiPicker: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("头像符号")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                LazyVGrid(columns: emojiColumns, spacing: 12) {
                    ForEach(MockData.avatarEmojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background {
                                    RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                                        .fill(selectedEmoji == emoji ? AppTheme.skyBlue.opacity(0.35) : AppTheme.glassFill)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                                        .stroke(selectedEmoji == emoji ? AppTheme.cyanGlow.opacity(0.6) : AppTheme.glassBorder, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var aliasField: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("昵称")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("输入昵称", text: $alias)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                            .fill(AppTheme.glassFill)
                    }
                Text("2–12 个字符，将在漂流瓶与广场中展示。")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    private var signatureField: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("个性签名")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("写一句代表自己的话", text: $signature, axis: .vertical)
                    .lineLimit(1...3)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                            .fill(AppTheme.glassFill)
                    }
            }
        }
    }

    private var saveButton: some View {
        GradientPrimaryButton(title: "保存资料", icon: "checkmark.circle.fill", isEnabled: canSave) {
            let trimmedAlias = alias.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedAlias.count >= 2, trimmedAlias.count <= 12 else { return }
            appState.updateAlias(trimmedAlias)
            appState.updateSignature(signature)
            appState.updateAvatarEmoji(selectedEmoji)
            dismiss()
        }
    }

    private var canSave: Bool {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 12
    }
}
