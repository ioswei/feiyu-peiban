import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showNotifications = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                OceanBackground()

                if appState.visibleConversations().isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("消息")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .navigationDestination(for: UUID.self) { conversationID in
                ChatView(conversationID: conversationID)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNotifications = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.badge.fill")
                                .font(.body)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(AppTheme.cyanGlow, AppTheme.textTertiary)
                            if appState.unreadNotificationCount > 0 {
                                Circle()
                                    .fill(Color(red: 1, green: 0.35, blue: 0.45))
                                    .frame(width: 9, height: 9)
                                    .offset(x: 5, y: -5)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
            .onAppear(perform: consumePendingNavigation)
            .onChange(of: appState.pendingOpenConversationID) { _ in
                consumePendingNavigation()
            }
            .onChange(of: appState.pendingShowNotifications) { _ in
                consumePendingNavigation()
            }
        }
    }

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                PageSectionHeader(
                    title: "我的邂逅",
                    subtitle: "共 \(appState.visibleConversations().count) 段因漂流瓶开始的对话"
                )

                ForEach(appState.visibleConversations()) { conversation in
                    NavigationLink(value: conversation.id) {
                        ConversationRow(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                }

                NewEncounterPromptCard()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
    }

    private func consumePendingNavigation() {
        if let id = appState.pendingOpenConversationID {
            path.append(id)
            appState.pendingOpenConversationID = nil
        }
        if appState.pendingShowNotifications {
            showNotifications = true
            appState.pendingShowNotifications = false
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.skyBlue.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.heroGradient)
            }
            Text("还没有邂逅")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            SectionCaption(text: "去海洋捡一个漂流瓶\n也许就能遇见另一个灵魂")

            NewEncounterPromptCard(compact: false)
                .padding(.horizontal, 4)
                .padding(.top, 8)
        }
        .padding()
    }
}

private struct NewEncounterPromptCard: View {
    @EnvironmentObject private var appState: AppState
    var compact: Bool = true

    var body: some View {
        Button {
            appState.openOceanTab()
        } label: {
            GlassCard(cornerRadius: AppTheme.radiusMD) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.skyBlue.opacity(0.2))
                            .frame(width: compact ? 48 : 56, height: compact ? 48 : 56)
                        DriftBottleIllustration(size: compact ? 44 : 52)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("想要新的邂逅？")
                            .font(compact ? .subheadline.weight(.semibold) : .headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("去海洋捡一个漂流瓶吧")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        if !compact {
                            Text("点击前往海洋")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(AppTheme.cyanGlow)
                                .padding(.top, 2)
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.cyanGlow)
                        .padding(8)
                        .background(AppTheme.skyBlue.opacity(0.18))
                        .clipShape(Circle())
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.radiusMD, style: .continuous)
                    .stroke(AppTheme.cyanGlow.opacity(0.22), lineWidth: 1)
            }
        }
        .buttonStyle(PressableCardButtonStyle())
        .accessibilityLabel("想要新的邂逅，去海洋捡漂流瓶")
        .accessibilityHint("切换到海洋页面")
    }
}

private struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ConversationRow: View {
    @EnvironmentObject private var appState: AppState
    let conversation: Conversation
    @State private var showReportSheet = false

    var body: some View {
        GlassCard(cornerRadius: AppTheme.radiusMD) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.avatarGradient.opacity(0.4))
                        .frame(width: 52, height: 52)
                    Text(conversation.partnerMood.emoji)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(conversation.partnerAlias)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text(conversation.lastMessageAt, style: .time)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Text(conversation.lastMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.buttonGradient)
                        .clipShape(Capsule())
                }
            }
        }
        .contextMenu {
            Button {
                showReportSheet = true
            } label: {
                Label("举报聊天", systemImage: "exclamationmark.bubble")
            }
            Button(role: .destructive) {
                appState.blockUser(conversation.partnerAlias)
            } label: {
                Label("屏蔽 \(conversation.partnerAlias)", systemImage: "hand.raised")
            }
        }
        .reportReasonSheet(isPresented: $showReportSheet, title: "举报聊天") { reason in
            appState.reportConversation(conversation, reason: reason)
        }
    }
}

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let conversationID: UUID

    @State private var draft = ""
    @State private var showReportSheet = false
    @State private var showSafetyAlert = false

    private var conversation: Conversation? {
        appState.conversations.first { $0.id == conversationID }
    }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                if let conversation {
                    originBottleBanner(conversation)

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(conversation.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(16)
                        }
                        .onChange(of: conversation.messages.count) { _ in
                            if let last = conversation.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    quickRepliesBar
                    inputBar
                } else {
                    chatUnavailableState
                }
            }
        }
        .navigationTitle(conversation?.partnerAlias ?? "对话")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .hidesTabBarWhenPushed()
        .toolbar {
            if let conversation {
                ToolbarItem(placement: .primaryAction) {
                    UserSafetyMenu(
                        targetAlias: conversation.partnerAlias,
                        reportTitle: "举报聊天",
                        onReport: { showReportSheet = true },
                        dismissOnBlock: true
                    )
                }
            }
        }
        .reportReasonSheet(isPresented: $showReportSheet, title: "举报聊天") { reason in
            if let conversation {
                appState.reportConversation(conversation, reason: reason)
                dismiss()
            }
        }
        .alert("无法发送", isPresented: $showSafetyAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(ContentSafety.rejectionMessage)
        }
        .onAppear {
            if conversation == nil {
                dismiss()
            } else {
                appState.markConversationRead(conversationID)
            }
        }
    }

    private var chatUnavailableState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textTertiary)
            Text("对话已不可用")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("可能已被删除或你已屏蔽对方")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var quickRepliesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MockData.quickReplies, id: \.self) { text in
                    Button(text) {
                        draft = text
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.glassFill)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.glassBorder, lineWidth: 1))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private func originBottleBanner(_ conversation: Conversation) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "envelope.open.fill")
                .foregroundStyle(AppTheme.cyanGlow)
                .font(.caption)
            Text("因漂流瓶相遇 · \(conversation.originBottleContent.prefix(28))…")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("说点什么…", text: $draft)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(AppTheme.glassFill)
                        .overlay(Capsule().stroke(AppTheme.glassBorder, lineWidth: 1))
                }
                .foregroundStyle(AppTheme.textPrimary)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(13)
                    .background {
                        Circle()
                            .fill(AppTheme.buttonGradient)
                            .shadow(color: AppTheme.cyanGlow.opacity(0.3), radius: 8)
                    }
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func sendMessage() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard appState.sendMessage(in: conversationID, content: text) else {
            showSafetyAlert = true
            return
        }
        draft = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromMe { Spacer(minLength: 48) }

            if !message.isFromMe {
                Circle()
                    .fill(AppTheme.skyBlue.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .overlay(Text("✦").font(.caption2).foregroundStyle(AppTheme.cyanGlow))
            }

            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background {
                        if message.isFromMe {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.bubbleMine)
                        } else {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(AppTheme.glassFill)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(AppTheme.glassBorder, lineWidth: 1)
                                )
                        }
                    }
                    .foregroundStyle(message.isFromMe ? .white : AppTheme.textPrimary)

                Text(message.sentAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            if !message.isFromMe { Spacer(minLength: 48) }
        }
    }
}

struct NotificationsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()

                if appState.notifications.isEmpty {
                    Text("暂无提醒")
                        .foregroundStyle(AppTheme.textTertiary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(appState.notifications) { notification in
                                Button {
                                    handleNotificationTap(notification)
                                } label: {
                                    NotificationRow(notification: notification)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("提醒")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationStyle()
            .hidesTabBarWhenPushed()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(AppTheme.cyanGlow)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("全部已读") {
                        appState.markAllNotificationsRead()
                    }
                    .foregroundStyle(AppTheme.cyanGlow)
                    .font(.caption.weight(.medium))
                }
            }
        }
    }

    private func handleNotificationTap(_ notification: AppNotification) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch notification.kind {
            case .newMessage, .encounter:
                if let conversation = appState.conversations.first(where: { $0.partnerAlias == notification.title }) {
                    appState.openMessagesTab(conversationID: conversation.id)
                } else {
                    appState.openMessagesTab()
                }
            case .bottleCaught:
                appState.openOceanTab()
            case .reminder:
                break
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        GlassCard(cornerRadius: AppTheme.radiusMD) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.skyBlue.opacity(0.25))
                        .frame(width: 40, height: 40)
                    Image(systemName: iconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.cyanGlow)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(notification.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if !notification.isRead {
                            Circle()
                                .fill(AppTheme.cyanGlow)
                                .frame(width: 6, height: 6)
                        }

                        Spacer(minLength: 0)
                    }

                    Text(notification.body)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(notification.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var iconName: String {
        switch notification.kind {
        case .bottleCaught: "drop.fill"
        case .newMessage: "bubble.left.fill"
        case .encounter: "sparkles"
        case .reminder: "bell.fill"
        }
    }
}
