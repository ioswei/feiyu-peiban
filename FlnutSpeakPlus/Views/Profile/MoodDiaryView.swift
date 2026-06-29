import SwiftUI

struct MoodDiaryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showCompose = false

    var body: some View {
        ZStack {
            OceanBackground()

            if appState.diaryEntries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        summaryBanner
                        streakBanner

                        ForEach(appState.diaryEntries) { entry in
                            NavigationLink {
                                DiaryDetailView(entry: entry)
                            } label: {
                                diaryCard(entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("心情日记")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(AppTheme.cyanGlow)
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeDiaryView()
        }
    }

    private var summaryBanner: some View {
        GlassCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("全部日记")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("\(appState.diaryEntries.count) 篇")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                if let mood = appState.dominantDiaryMood() {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("常见心情")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("\(mood.emoji) \(mood.rawValue)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.cyanGlow)
                    }
                }
            }
        }
    }

    private var streakBanner: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("连续记录")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("\(appState.diaryStreakDays) 天")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(AppTheme.heroGradient)
                    .font(.title2)
            }
        }
    }

    private func diaryCard(_ entry: DiaryEntry) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(entry.mood.emoji)
                    Text(entry.mood.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.cyanGlow)
                    Spacer()
                    Text(entry.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary.opacity(0.7))
                }
                Text(entry.content)
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
                    .lineSpacing(5)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.heroGradient)
            Text("还没有私密日记")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            SectionCaption(text: "只写给自己的话，不会被任何人看到")
            GradientPrimaryButton(title: "写第一篇日记", icon: "pencil") {
                showCompose = true
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

struct DiaryDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let entry: DiaryEntry

    @State private var showDeleteConfirm = false
    @State private var showEditSheet = false

    private var liveEntry: DiaryEntry? {
        appState.diaryEntries.first { $0.id == entry.id }
    }

    var body: some View {
        ZStack {
            OceanBackground()

            if let entry = liveEntry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(entry.mood.emoji)
                                        .font(.title)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.mood.rawValue)
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.textPrimary)
                                        Text(entry.createdAt.formatted(date: .complete, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textTertiary)
                                    }
                                    Spacer()
                                }

                                Rectangle()
                                    .fill(AppTheme.glassBorder)
                                    .frame(height: 1)

                                Text(entry.content)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.textPrimary.opacity(0.95))
                                    .lineSpacing(8)
                            }
                        }

                        Label("这篇日记仅保存在你的设备，不会同步到广场或海洋。", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(20)
                }
            } else {
                Text("日记已删除")
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .navigationTitle("日记详情")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
        .toolbar {
            if liveEntry != nil {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(AppTheme.cyanGlow)
                    }
                }
            }
        }
        .confirmationDialog("删除这篇日记？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                if let entry = liveEntry {
                    appState.deleteDiaryEntry(entry)
                }
                dismiss()
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showEditSheet) {
            if let entry = liveEntry {
                EditDiaryView(entry: entry)
            }
        }
    }
}

struct EditDiaryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let entry: DiaryEntry

    @State private var content: String = ""
    @State private var mood: BottleMood = .lonely
    @State private var showSafetyAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()

                VStack(spacing: 20) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
                        ForEach(BottleMood.allCases) { m in
                            MoodChip(mood: m, isSelected: mood == m) {
                                mood = m
                            }
                        }
                    }

                    TextEditor(text: $content)
                        .frame(minHeight: 180)
                        .appTextEditorStyle()

                    GradientPrimaryButton(title: "保存修改", icon: "checkmark.circle.fill", isEnabled: canSave) {
                        guard appState.updateDiaryEntry(entry, content: content, mood: mood) else {
                            showSafetyAlert = true
                            return
                        }
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle("编辑日记")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppTheme.cyanGlow)
                }
            }
            .alert("无法保存", isPresented: $showSafetyAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(ContentSafety.rejectionMessage)
            }
            .onAppear {
                content = entry.content
                mood = entry.mood
            }
        }
    }

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ComposeDiaryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var mood: BottleMood = .lonely
    @State private var showSafetyAlert = false

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()

                VStack(spacing: 20) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
                        ForEach(BottleMood.allCases) { m in
                            MoodChip(mood: m, isSelected: mood == m) {
                                mood = m
                            }
                        }
                    }

                    TextEditor(text: $content)
                        .frame(minHeight: 180)
                        .appTextEditorStyle()

                    Label("私密日记不会出现在广场或漂流瓶", systemImage: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    GradientPrimaryButton(title: "保存日记", icon: "checkmark.circle.fill", isEnabled: canSave) {
                        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard appState.addDiaryEntry(content: text, mood: mood) else {
                            showSafetyAlert = true
                            return
                        }
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle("写日记")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .hidesTabBarWhenPushed()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppTheme.cyanGlow)
                }
            }
            .alert("无法保存", isPresented: $showSafetyAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(ContentSafety.rejectionMessage)
            }
        }
    }
}
