import SwiftUI

/// 通用 UGC 安全操作菜单（举报 / 屏蔽 / 拉黑）
struct UserSafetyMenu: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let targetAlias: String?
    let reportTitle: String
    var allowBlock: Bool = true
    var onReport: () -> Void
    var dismissOnBlock: Bool = false

    var body: some View {
        Menu {
            Button {
                onReport()
            } label: {
                Label(reportTitle, systemImage: "exclamationmark.bubble")
            }

            if allowBlock, let targetAlias, targetAlias != appState.userAlias {
                Button(role: .destructive) {
                    appState.blockUser(targetAlias)
                    if dismissOnBlock { dismiss() }
                } label: {
                    Label("拉黑 \(targetAlias)", systemImage: "person.crop.circle.badge.xmark")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
                .foregroundStyle(AppTheme.cyanGlow)
        }
    }
}

/// 匿名内容仅举报
struct AnonymousReportMenu: View {
    let reportTitle: String
    var onReport: () -> Void

    var body: some View {
        Menu {
            Button {
                onReport()
            } label: {
                Label(reportTitle, systemImage: "exclamationmark.bubble")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
                .foregroundStyle(AppTheme.cyanGlow)
        }
    }
}

extension View {
    func reportReasonSheet(
        isPresented: Binding<Bool>,
        title: String,
        onSubmit: @escaping (ReportReason) -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            ReportReasonSheet(title: title, onSubmit: onSubmit)
        }
    }
}

/// 评论安全操作按钮（举报 / 屏蔽 / 拉黑）
struct CommentSafetyMenuButton: View {
    let onReport: () -> Void
    let onHide: () -> Void
    let onBlock: () -> Void

    var body: some View {
        Menu {
            Button(action: onReport) {
                Label("举报", systemImage: "exclamationmark.bubble")
            }
            Button(action: onHide) {
                Label("屏蔽此评论", systemImage: "eye.slash")
            }
            Button(role: .destructive, action: onBlock) {
                Label("拉黑用户", systemImage: "person.crop.circle.badge.xmark")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
                .foregroundStyle(AppTheme.cyanGlow.opacity(0.9))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("评论操作")
        .accessibilityHint("举报、屏蔽或拉黑")
    }
}
