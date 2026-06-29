import SwiftUI

struct MoodSquareView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showPublishSheet = false
    @State private var moodFilter: CatchMoodFilter = .any
    @State private var path = NavigationPath()

    private var filteredPosts: [MoodPost] {
        appState.visibleMoodPosts(filter: moodFilter)
    }

    private var hasAnyPosts: Bool {
        !appState.visibleMoodPosts().isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                OceanBackground()

                if !hasAnyPosts {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            PageSectionHeader(
                                title: "今日情绪流",
                                subtitle: "看看同频的人，正在想什么"
                            )
                            .padding(.top, 4)

                            squareFilterRow

                            ForEach(filteredPosts) { post in
                                MoodPostCard(post: post) {
                                    path.append(post.id)
                                }
                            }

                            footerHint
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("心情广场")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .navigationDestination(for: UUID.self) { postID in
                MoodPostDetailView(postID: postID)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showPublishSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(AppTheme.cyanGlow, AppTheme.skyBlue.opacity(0.5))
                    }
                }
            }
            .sheet(isPresented: $showPublishSheet) {
                PublishMoodView()
            }
        }
    }

    private var footerHint: some View {
        Text(filteredPosts.isEmpty ? "这个心情下暂无动态" : "— 更多心情，正在漂来 —")
            .font(.caption)
            .foregroundStyle(AppTheme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    private var squareFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CatchMoodFilter.allCases) { filter in
                    Button {
                        moodFilter = filter
                    } label: {
                        HStack(spacing: 4) {
                            Text(filter.emoji)
                            Text(filter.rawValue)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(moodFilter == filter ? AppTheme.skyBlue.opacity(0.35) : AppTheme.glassFill)
                        .foregroundStyle(AppTheme.textPrimary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.skyBlue.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.heroGradient)
            }
            Text("还没有心情动态")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            SectionCaption(text: "分享第一条心情，让广场开始有温度")
            GradientPrimaryButton(title: "发布心情", icon: "square.and.pencil") {
                showPublishSheet = true
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding()
    }
}

struct MoodPostCard: View {
    @EnvironmentObject private var appState: AppState
    let post: MoodPost
    var onOpen: () -> Void
    @State private var liked = false
    @State private var showReportSheet = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Button(action: onOpen) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.avatarGradient.opacity(0.35))
                                    .frame(width: 44, height: 44)
                                Text(post.mood.emoji)
                                    .font(.body)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(post.authorAlias)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("\(post.mood.rawValue) · \(post.createdAt, style: .relative)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            Spacer()
                        }

                        Text(post.content)
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
                            .lineSpacing(5)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)

                HStack {
                    Button {
                        guard !liked else { return }
                        withAnimation(.spring(response: 0.3)) {
                            liked = true
                            appState.likePost(post)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: liked ? "heart.fill" : "heart")
                            Text("\(displayLikeCount)")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(liked ? AppTheme.cyanGlow : AppTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background {
                            Capsule()
                                .fill(liked ? AppTheme.cyanGlow.opacity(0.15) : AppTheme.glassFill)
                        }
                    }
                    .buttonStyle(.plain)

                    if appState.commentCount(for: post.id) > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                            Text("\(appState.commentCount(for: post.id))")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textTertiary)
                    }

                    Spacer()

                    Button(action: onOpen) {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.textTertiary.opacity(0.7))
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contextMenu {
            if post.authorAlias != appState.userAlias {
                Button {
                    showReportSheet = true
                } label: {
                    Label("举报动态", systemImage: "exclamationmark.bubble")
                }
                Button(role: .destructive) {
                    appState.blockUser(post.authorAlias)
                } label: {
                    Label("屏蔽用户", systemImage: "hand.raised")
                }
            }
        }
        .reportReasonSheet(isPresented: $showReportSheet, title: "举报动态") { reason in
            appState.reportPost(post, reason: reason)
        }
    }

    private var displayLikeCount: Int {
        appState.moodPosts.first(where: { $0.id == post.id })?.likeCount ?? post.likeCount
    }
}

struct PublishMoodView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var selectedMood: BottleMood = .lonely
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
                    ScrollView {
                        VStack(spacing: 20) {
                            LazyVGrid(columns: moodColumns, spacing: 10) {
                                ForEach(BottleMood.allCases) { mood in
                                    MoodChip(mood: mood, isSelected: selectedMood == mood) {
                                        selectedMood = mood
                                    }
                                }
                            }

                            TextEditor(text: $content)
                                .frame(minHeight: 140)
                                .appTextEditorStyle()

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
                        .padding(20)
                    }

                    VStack(spacing: 0) {
                        Divider().overlay(AppTheme.glassBorder)
                        GradientPrimaryButton(title: "发布到广场", icon: "arrow.up.circle.fill", isEnabled: canSubmit) {
                            let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }
                            guard appState.publishMood(content: text, mood: selectedMood) else {
                                showSafetyAlert = true
                                return
                            }
                            dismiss()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("发布心情")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .hidesTabBarWhenPushed()
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppTheme.cyanGlow)
                }
            }
            .alert("无法发布", isPresented: $showSafetyAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(ContentSafety.rejectionMessage)
            }
        }
    }
}
