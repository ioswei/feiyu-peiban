import SwiftUI

struct MoodPostDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let postID: UUID

    @State private var liked = false
    @State private var commentText = ""
    @State private var showReportSheet = false
    @State private var reportingComment: MoodComment?
    @State private var showBlockConfirm = false
    @State private var showHidePostConfirm = false
    @State private var commentToHide: MoodComment?
    @State private var commentToBlock: MoodComment?
    @State private var showSafetyAlert = false
    @State private var safetyMessage = ""

    private var post: MoodPost? {
        appState.post(by: postID)
    }

    private var comments: [MoodComment] {
        appState.comments(for: postID)
    }

    var body: some View {
        Group {
            if let post {
                detailContent(for: post)
            } else {
                unavailableState
            }
        }
        .navigationTitle("心情详情")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
        .alert("提示", isPresented: $showSafetyAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(safetyMessage)
        }
        .reportReasonSheet(isPresented: $showReportSheet, title: "举报动态") { reason in
            if let post { appState.reportPost(post, reason: reason) }
            dismiss()
        }
        .sheet(item: $reportingComment) { comment in
            ReportReasonSheet(title: "举报评论") { reason in
                appState.reportComment(comment, reason: reason)
                reportingComment = nil
            }
        }
        .confirmationDialog("拉黑该用户？", isPresented: $showBlockConfirm, titleVisibility: .visible) {
            Button("拉黑 \(post?.authorAlias ?? "该用户")", role: .destructive) {
                if let alias = post?.authorAlias {
                    appState.blockUser(alias)
                }
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("拉黑后将不再看到 TA 的动态、评论、漂流瓶与聊天。")
        }
        .confirmationDialog("屏蔽此动态？", isPresented: $showHidePostConfirm, titleVisibility: .visible) {
            Button("屏蔽此动态") {
                if let post {
                    appState.hidePost(post)
                }
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("仅隐藏这条动态，不会拉黑该用户。")
        }
        .confirmationDialog("屏蔽此评论？", isPresented: hideCommentDialogPresented, titleVisibility: .visible) {
            Button("屏蔽此评论") {
                if let comment = commentToHide {
                    appState.hideComment(comment)
                }
                commentToHide = nil
            }
            Button("取消", role: .cancel) {
                commentToHide = nil
            }
        } message: {
            Text("仅隐藏这条评论，不会拉黑该用户。")
        }
        .confirmationDialog("拉黑该用户？", isPresented: blockCommentDialogPresented, titleVisibility: .visible) {
            Button("拉黑 \(commentToBlock?.authorAlias ?? "该用户")", role: .destructive) {
                if let alias = commentToBlock?.authorAlias {
                    appState.blockUser(alias)
                }
                commentToBlock = nil
            }
            Button("取消", role: .cancel) {
                commentToBlock = nil
            }
        } message: {
            Text("拉黑后将不再看到 TA 的动态、评论、漂流瓶与聊天。")
        }
    }

    private var hideCommentDialogPresented: Binding<Bool> {
        Binding(
            get: { commentToHide != nil },
            set: { if !$0 { commentToHide = nil } }
        )
    }

    private var blockCommentDialogPresented: Binding<Bool> {
        Binding(
            get: { commentToBlock != nil },
            set: { if !$0 { commentToBlock = nil } }
        )
    }

    @ViewBuilder
    private func detailContent(for post: MoodPost) -> some View {
        ZStack {
            OceanBackground()

            ScrollView {
                VStack(spacing: 16) {
                    postHeroCard(post)
                    interactionBar(post)
                    commentsSection
                    safetyFooter
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showReportSheet = true
                    } label: {
                        Label("举报", systemImage: "exclamationmark.bubble")
                    }

                    if post.authorAlias != appState.userAlias {
                        Button {
                            showHidePostConfirm = true
                        } label: {
                            Label("屏蔽此动态", systemImage: "eye.slash")
                        }

                        Button(role: .destructive) {
                            showBlockConfirm = true
                        } label: {
                            Label("拉黑用户", systemImage: "person.crop.circle.badge.xmark")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body)
                        .foregroundStyle(AppTheme.cyanGlow)
                }
            }
        }
    }

    private func postHeroCard(_ post: MoodPost) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.avatarGradient.opacity(0.4))
                            .frame(width: 56, height: 56)
                        Text(post.mood.emoji)
                            .font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.authorAlias)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(post.mood.rawValue) · \(post.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                }

                Text(post.content)
                    .font(.title3.weight(.regular))
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.95))
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 8)
    }

    private func interactionBar(_ post: MoodPost) -> some View {
        HStack(spacing: 12) {
            Button {
                guard !liked else { return }
                withAnimation(.spring(response: 0.3)) {
                    liked = true
                    appState.likePost(post)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: liked ? "heart.fill" : "heart")
                    Text("\(displayLikeCount(for: post))")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(liked ? AppTheme.cyanGlow : AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(liked ? AppTheme.cyanGlow.opacity(0.15) : AppTheme.glassFill)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right")
                Text("\(comments.count)")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule().fill(AppTheme.glassFill)
            }

            Spacer()
        }
    }

    private var commentsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("同频回应")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                if comments.isEmpty {
                    Text("还没有人回应，做第一个留下温度的人吧。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ForEach(comments) { comment in
                        commentRow(comment)
                        if comment.id != comments.last?.id {
                            Rectangle()
                                .fill(AppTheme.glassBorder)
                                .frame(height: 1)
                        }
                    }
                }

                commentComposer
            }
        }
    }

    private func commentRow(_ comment: MoodComment) -> some View {
        let isOthersComment = comment.authorAlias != appState.userAlias

        return HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AppTheme.skyBlue.opacity(0.25))
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(comment.authorAlias.prefix(1)))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.cyanGlow)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorAlias)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(comment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                    Spacer(minLength: 0)
                    if isOthersComment {
                        CommentSafetyMenuButton(
                            onReport: { reportingComment = comment },
                            onHide: { commentToHide = comment },
                            onBlock: { commentToBlock = comment }
                        )
                    }
                }
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            if isOthersComment {
                commentSafetyMenuItems(
                    onReport: { reportingComment = comment },
                    onHide: { commentToHide = comment },
                    onBlock: { commentToBlock = comment }
                )
            }
        }
    }

    @ViewBuilder
    private func commentSafetyMenuItems(
        onReport: @escaping () -> Void,
        onHide: @escaping () -> Void,
        onBlock: @escaping () -> Void
    ) -> some View {
        Button(action: onReport) {
            Label("举报", systemImage: "exclamationmark.bubble")
        }
        Button(action: onHide) {
            Label("屏蔽此评论", systemImage: "eye.slash")
        }
        Button(role: .destructive, action: onBlock) {
            Label("拉黑用户", systemImage: "person.crop.circle.badge.xmark")
        }
    }

    private var commentComposer: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("写下一句温柔的回应…", text: $commentText, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                        .fill(AppTheme.glassFill)
                }
                .foregroundStyle(AppTheme.textPrimary)

            HStack {
                Text("友善表达，彼此尊重")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
                Spacer()
                Button("发送") {
                    submitComment()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canSubmitComment ? AppTheme.cyanGlow : AppTheme.textTertiary)
                .disabled(!canSubmitComment)
            }
        }
        .padding(.top, 4)
    }

    private var safetyFooter: some View {
        Link(destination: URL(string: "mailto:\(AppSupport.contactEmail)")!) {
            Label("联系支持：\(AppSupport.contactEmail)", systemImage: "envelope")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var unavailableState: some View {
        ZStack {
            OceanBackground()
            VStack(spacing: 12) {
                Image(systemName: "eye.slash")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.textTertiary)
                Text("这条动态已不可见")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("可能已被删除、举报或你已屏蔽该用户。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding()
        }
    }

    private var canSubmitComment: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func displayLikeCount(for post: MoodPost) -> Int {
        appState.moodPosts.first(where: { $0.id == post.id })?.likeCount ?? post.likeCount
    }

    private func submitComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard appState.addComment(to: postID, content: text) else {
            safetyMessage = ContentSafety.rejectionMessage
            showSafetyAlert = true
            return
        }
        commentText = ""
    }
}

struct CommunityGuidelinesView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OceanBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        headerBlock

                        guidelineSection(
                            title: "我们欢迎",
                            icon: "heart.circle.fill",
                            items: [
                                "真诚分享情绪与心事，彼此倾听与陪伴",
                                "尊重匿名身份，不追问线下真实信息",
                                "用温和的语言回应，让广场保持安全"
                            ]
                        )

                        guidelineSection(
                            title: "我们禁止",
                            icon: "xmark.octagon.fill",
                            items: [
                                "色情、暴力、仇恨、骚扰与违法内容",
                                "索要联系方式、引流至站外进行欺诈",
                                "冒充他人、恶意刷屏或干扰社区秩序"
                            ]
                        )

                        safetyToolsSection

                        Spacer(minLength: 12)

                        contactSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 12))
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .topLeading)
                }
            }
        }
        .navigationTitle("社区规范")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
    }

    private var headerBlock: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("飞语陪伴 · 安全社区")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("心情广场与漂流瓶均为用户生成内容。我们采用匿名昵称保护隐私，同时提供举报、屏蔽与内容过滤，让社区保持温柔与安全。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func guidelineSection(title: String, icon: String, items: [String]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(AppTheme.cyanGlow.opacity(0.6))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var safetyToolsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("你的安全工具")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                safetyToolRow(icon: "exclamationmark.bubble", title: "举报", detail: "选择举报原因后提交，App 会打开邮件并附带内容编号；匿名漂流瓶同样可举报。我们会在 \(AppSupport.reviewResponseHours) 小时内处理。")
                safetyToolRow(icon: "hand.raised", title: "屏蔽", detail: "屏蔽后不再看到该用户的漂流瓶、动态、评论与聊天。")
                safetyToolRow(icon: "text.badge.checkmark", title: "内容过滤", detail: "发布瓶子、动态、评论与聊天消息时会进行基础关键词过滤。")
                safetyToolRow(icon: "doc.text", title: "法律文件", detail: "可在「我的」页查看隐私政策与用户协议。")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func safetyToolRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.cyanGlow)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineSpacing(3)
            }
        }
    }

    private var contactSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("需要帮助？")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("如对社区内容、隐私或账号安全有疑问，请通过邮件联系我们，我们会尽快回复。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Link(destination: AppSupport.communityGuidelinesURL) {
                    Label("在线社区规范", systemImage: "safari")
                        .font(.caption.weight(.medium))
                }

                Link(destination: URL(string: "mailto:\(AppSupport.contactEmail)")!) {
                    Label(AppSupport.contactEmail, systemImage: "envelope.fill")
                        .font(.subheadline.weight(.medium))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
