import SwiftUI

/// 举报原因选择 — App Store UGC 审核要求明确举报分类
struct ReportReasonSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSubmit: (ReportReason) -> Void

    @State private var selectedReason: ReportReason?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.abyss.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("请选择举报原因，我们会在 \(AppSupport.reviewResponseHours) 小时内处理。恶意举报可能导致账号受限。")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineSpacing(4)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            ForEach(ReportReason.allCases) { reason in
                                reasonRow(reason)
                            }
                        }

                        GradientPrimaryButton(
                            title: "提交举报",
                            icon: "paperplane.fill",
                            isEnabled: selectedReason != nil
                        ) {
                            if let selectedReason {
                                onSubmit(selectedReason)
                                dismiss()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppTheme.cyanGlow)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func reasonRow(_ reason: ReportReason) -> some View {
        Button {
            selectedReason = reason
        } label: {
            HStack(spacing: 14) {
                Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedReason == reason ? AppTheme.cyanGlow : AppTheme.textTertiary)
                Text(reason.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                    .fill(selectedReason == reason ? AppTheme.skyBlue.opacity(0.22) : AppTheme.glassFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                            .stroke(
                                selectedReason == reason ? AppTheme.cyanGlow.opacity(0.45) : AppTheme.glassBorder,
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}
