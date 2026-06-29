import SwiftUI

struct ThrowBottleView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var selectedMood: BottleMood = .lonely
    @State private var isAnonymous = true
    @State private var didThrow = false
    @State private var agreedToGuidelines = false
    @State private var showSafetyAlert = false

    private let moodColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var canSubmit: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && agreedToGuidelines
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 16) {
                                DriftBottleIllustration(size: 72)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("写下心事，封进瓶里")
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("让它漂向蓝色海洋")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.bottom, 4)

                            moodPicker

                            VStack(alignment: .leading, spacing: 8) {
                                Text("瓶中信")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)

                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $content)
                                        .frame(minHeight: 120, maxHeight: 160)
                                        .appTextEditorStyle()

                                    if content.isEmpty {
                                        Text("今晚又想了很多…")
                                            .foregroundStyle(AppTheme.textTertiary)
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 18)
                                            .allowsHitTesting(false)
                                    }
                                }
                            }

                            Toggle(isOn: $isAnonymous) {
                                Text("匿名投递")
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            .tint(AppTheme.cyanGlow)

                            Toggle(isOn: $agreedToGuidelines) {
                                Text("我已阅读并同意社区规范")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .tint(AppTheme.cyanGlow)

                            NavigationLink {
                                CommunityGuidelinesView()
                            } label: {
                                Label("查看社区规范", systemImage: "doc.text")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AppTheme.cyanGlow)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }

                    VStack(spacing: 0) {
                        Divider().overlay(AppTheme.glassBorder)
                        GradientPrimaryButton(title: "漂向大海", icon: "paperplane.fill", isEnabled: canSubmit) {
                            throwBottle()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 12)
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("扔漂流瓶")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .hidesTabBarWhenPushed()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppTheme.cyanGlow)
                }
            }
            .presentationDragIndicator(.visible)
            .alert("瓶子已漂向大海", isPresented: $didThrow) {
                Button("好的") { dismiss() }
            } message: {
                Text("也许很快，就会有一个孤独的灵魂捡到它。")
            }
            .alert("无法投递", isPresented: $showSafetyAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(ContentSafety.rejectionMessage)
            }
        }
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("此刻心情")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            LazyVGrid(columns: moodColumns, spacing: 10) {
                ForEach(BottleMood.allCases) { mood in
                    MoodChip(mood: mood, isSelected: selectedMood == mood) {
                        selectedMood = mood
                    }
                }
            }
        }
    }

    private func throwBottle() {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard appState.throwBottle(content: text, mood: selectedMood, isAnonymous: isAnonymous) else {
            showSafetyAlert = true
            return
        }
        didThrow = true
    }
}
