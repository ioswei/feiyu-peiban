import SwiftUI

struct EmailLoginView: View {
    @EnvironmentObject private var appState: AppState

    @State private var email = AuthStore.lastLoggedInEmail ?? ""
    @State private var verificationCode = ""
    @State private var isSubmitting = false
    @State private var isSendingCode = false
    @State private var errorMessage: String?
    @State private var successHint: String?
    @State private var resendCountdown = 0
    @State private var countdownTimer: Timer?
    @State private var agreedToLegal = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case code
    }

    private var canSendCode: Bool {
        AuthStore.isValidEmail(email) && resendCountdown == 0 && !isSendingCode
    }

    private var canSubmit: Bool {
        AuthStore.isValidEmail(email)
            && verificationCode.count == 6
            && agreedToLegal
            && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OceanBackground()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        formCard
                        hintSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
            }
            .navigationBarHidden(true)
            .onDisappear {
                countdownTimer?.invalidate()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.skyBlue.opacity(0.18))
                    .frame(width: 96, height: 96)
                BrandIconView(size: 72)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 72, height: 72)
            }

            VStack(spacing: 8) {
                Text("飞语陪伴")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("用邮箱验证码登录，开启你的海洋之旅")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.top, 24)
    }

    private var formCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("邮箱登录")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("邮箱")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textTertiary)

                    TextField(
                        "",
                        text: $email,
                        prompt: Text("请输入邮箱").foregroundColor(AppTheme.textTertiary)
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .code }
                    .padding(14)
                    .background(fieldBackground)
                    .foregroundStyle(AppTheme.textPrimary)
                    .tint(AppTheme.cyanGlow)
                    .onChange(of: email) { _ in
                        successHint = nil
                        errorMessage = nil
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("验证码")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textTertiary)

                    HStack(spacing: 10) {
                        TextField(
                            "",
                            text: $verificationCode,
                            prompt: Text("6 位数字").foregroundColor(AppTheme.textTertiary)
                        )
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($focusedField, equals: .code)
                        .onChange(of: verificationCode) { newValue in
                            let filtered = newValue.filter(\.isNumber)
                            verificationCode = String(filtered.prefix(6))
                        }
                        .padding(14)
                        .background(fieldBackground)
                        .foregroundStyle(AppTheme.textPrimary)
                        .tint(AppTheme.cyanGlow)

                        Button {
                            sendCode()
                        } label: {
                            Text(sendCodeButtonTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(canSendCode ? AppTheme.cyanGlow : AppTheme.textTertiary)
                                .frame(minWidth: 88)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 14)
                                .background {
                                    RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                                        .fill(canSendCode ? AppTheme.skyBlue.opacity(0.22) : AppTheme.glassFill)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                                                .stroke(AppTheme.glassBorder, lineWidth: 1)
                                        }
                                }
                        }
                        .disabled(!canSendCode)
                        .buttonStyle(.plain)
                    }
                }

                if let successHint {
                    Label(successHint, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.cyanGlow)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.orange.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }

                legalAgreementSection

                GradientPrimaryButton(
                    title: submitButtonTitle,
                    icon: "arrow.right.circle.fill",
                    isEnabled: canSubmit
                ) {
                    submit()
                }
                .padding(.top, 4)
            }
        }
    }

    private var legalAgreementSection: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    agreedToLegal.toggle()
                }
            } label: {
                Image(systemName: agreedToLegal ? "checkmark.circle.fill" : "circle")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(agreedToLegal ? AppTheme.cyanGlow : AppTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(agreedToLegal ? "已同意协议" : "未同意协议")

            agreementInlineRow
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                        .stroke(AppTheme.glassBorder.opacity(0.55), lineWidth: 1)
                }
        }
    }

    private var agreementInlineRow: some View {
        HStack(spacing: 0) {
            Text("登录即表示同意 ")
                .foregroundStyle(AppTheme.textSecondary)
            legalLink("用户协议", destination: TermsOfServiceView())
            Text("、")
                .foregroundStyle(AppTheme.textSecondary)
            legalLink("隐私政策", destination: PrivacyPolicyView())
            Text("和")
                .foregroundStyle(AppTheme.textSecondary)
            legalLink("社区规范", destination: CommunityGuidelinesView())
        }
        .font(.caption)
        .lineLimit(2)
        .minimumScaleFactor(0.88)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legalLink<D: View>(_ title: String, destination: D) -> some View {
        NavigationLink {
            destination
        } label: {
            Text(title)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.cyanGlow)
        }
        .buttonStyle(.plain)
    }

    private var hintSection: some View {
        VStack(spacing: 10) {
            Text("首次登录将自动创建账号，无需单独注册。")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)

            Text("本产品适合 17 岁及以上用户使用。")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var sendCodeButtonTitle: String {
        if isSendingCode { return "发送中" }
        if resendCountdown > 0 { return "\(resendCountdown)s" }
        return "获取验证码"
    }

    private var submitButtonTitle: String {
        if isSubmitting { return "登录中…" }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || !AuthStore.isValidEmail(trimmed) {
            return "继续"
        }
        return AuthStore.accountExists(trimmed) ? "登录" : "注册并登录"
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
            .fill(AppTheme.glassFill)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.radiusSM, style: .continuous)
                    .stroke(AppTheme.glassBorder, lineWidth: 1)
            }
    }

    private func sendCode() {
        guard canSendCode else { return }
        focusedField = nil
        errorMessage = nil
        successHint = nil
        isSendingCode = true

        let outcome = AuthStore.sendVerificationCode(to: email)
        isSendingCode = false

        switch outcome {
        case .sent(let hint):
            successHint = hint
            startResendCountdown()
            focusedField = .code
        case .invalidEmail:
            errorMessage = "请输入有效的邮箱地址。"
        case .tooFrequent(let remaining):
            resendCountdown = remaining
            errorMessage = "请 \(remaining) 秒后再获取验证码。"
        }
    }

    private func startResendCountdown() {
        resendCountdown = Int(AuthStore.resendCooldownRemaining(for: email))
        guard resendCountdown > 0 else { return }

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            resendCountdown = AuthStore.resendCooldownRemaining(for: email)
            if resendCountdown <= 0 {
                timer.invalidate()
                countdownTimer = nil
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        focusedField = nil
        errorMessage = nil
        isSubmitting = true

        let outcome = appState.loginWithVerificationCode(email, code: verificationCode)

        isSubmitting = false
        switch outcome {
        case .success:
            errorMessage = nil
        case .invalidEmail:
            errorMessage = "请输入有效的邮箱地址。"
        case .invalidCode:
            errorMessage = "验证码不正确，请重试。"
        case .codeExpired:
            errorMessage = "验证码已过期，请重新获取。"
        case .codeNotRequested:
            errorMessage = "请先点击「获取验证码」。"
        }
    }
}
