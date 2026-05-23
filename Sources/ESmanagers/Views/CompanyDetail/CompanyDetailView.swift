import SwiftUI
import CoreData

struct CompanyDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.openURL)             private var openURL

    @StateObject private var viewModel: CompanyDetailViewModel

    @State private var showEditSheet        = false
    @State private var showESBoxCreate      = false
    @State private var showInterviewCreate  = false
    @State private var editingInterview:    Interview? = nil
    @State private var showEditInterview    = false

    init(company: Company) {
        _viewModel = StateObject(wrappedValue: CompanyDetailViewModel(company: company))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            scrollContent
            toastOverlay
        }
        .background(Color.systemGroupedBackground.ignoresSafeArea())
        .navigationTitle(viewModel.company.name ?? "企業詳細")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: editButtonPlacement) {
                Button { showEditSheet = true } label: {
                    Image(systemName: "pencil")
                        .fontWeight(.medium)
                }
            }
        }
        // ESBox → ESBoxDetailView への遷移先
        .navigationDestination(for: ESBox.self) { esBox in
            ESBoxDetailView(esBox: esBox)
        }
        // 企業情報編集シート
        .sheet(isPresented: $showEditSheet, onDismiss: { viewModel.refreshCompanyData() }) {
            CompanyEditView(company: viewModel.company)
                .environment(\.managedObjectContext, context)
        }
        // ES BOX 作成シート
        .sheet(isPresented: $showESBoxCreate) {
            ESBoxCreateView { title, deadline in
                viewModel.addESBox(title: title, deadline: deadline, in: context)
            }
        }
        // 面接追加シート
        .sheet(isPresented: $showInterviewCreate) {
            InterviewCreateView { stage, startAt, mode in
                viewModel.addInterview(stage: stage, startAt: startAt, mode: mode, in: context)
            }
        }
        // 面接編集シート
        .sheet(isPresented: $showEditInterview) {
            if let interview = editingInterview {
                InterviewEditView(interview: interview) { stage, startAt, mode in
                    viewModel.updateInterview(interview, stage: stage, startAt: startAt, mode: mode, in: context)
                }
            }
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                loginSupportCard
                esBoxSection
                interviewSection
            }
            .padding(16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Toast overlay

    @ViewBuilder
    private var toastOverlay: some View {
        if viewModel.showToast {
            ToastView(message: viewModel.toastMessage)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 48)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Login support card

    private var loginSupportCard: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ヘッダー
            HStack {
                Label("ログイン情報", systemImage: "key.fill")
                    .font(.headline)
                Spacer()
                Button {
                    showEditSheet = true
                } label: {
                    Label("編集", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(Color.accentColor)
            }

            // URL セクション
            urlSection

            Divider()

            // ログインID セクション
            loginIDSection

            Divider()

            // パスワード行（常に表示）
            credentialRow(
                icon: "lock.circle.fill",
                label: "パスワード",
                value: viewModel.passwordDisplayText,
                isSet: viewModel.hasPassword,
                monospaced: viewModel.isPasswordVisible
            ) {
                passwordRowActions
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - URL section

    @ViewBuilder
    private var urlSection: some View {
        if viewModel.myPageURL != nil {
            Button {
                viewModel.openURLAndCopyID(open: openURL)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "safari")
                        .font(.system(size: 16, weight: .semibold))
                    Text(viewModel.company.myPageURL.nilIfEmpty ?? "")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        } else {
            warningButton(
                icon:  "safari",
                text:  "マイページURLが未設定です",
                hint:  "タップして設定する"
            ) { showEditSheet = true }
        }
    }

    // MARK: - LoginID section

    @ViewBuilder
    private var loginIDSection: some View {
        if viewModel.company.loginID.nilIfEmpty != nil {
            credentialRow(
                icon: "person.circle.fill",
                label: "ログインID",
                value: viewModel.company.loginID ?? "",
                isSet: true
            ) {
                Button {
                    viewModel.copyLoginID()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        } else {
            warningButton(
                icon:  "person.circle.fill",
                text:  "ログインIDが未設定です",
                hint:  "タップして設定する"
            ) { showEditSheet = true }
        }
    }

    // MARK: - Password row actions

    @ViewBuilder
    private var passwordRowActions: some View {
        if viewModel.isAuthenticating {
            ProgressView().scaleEffect(0.85).frame(width: 44)
        } else {
            HStack(spacing: 14) {
                if viewModel.isPasswordVisible {
                    Button {
                        Task { await viewModel.copyPassword() }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    Task { await viewModel.togglePasswordVisibility() }
                } label: {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundStyle(viewModel.canTogglePassword ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canTogglePassword)
            }
        }
    }

    // MARK: - Shared credential row

    @ViewBuilder
    private func credentialRow<Trailing: View>(
        icon: String,
        label: String,
        value: String,
        isSet: Bool,
        monospaced: Bool = false,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Group {
                    if monospaced { Text(value).monospaced() }
                    else          { Text(value) }
                }
                .font(.subheadline)
                .foregroundStyle(isSet ? Color.primary : Color.secondary)
                .animation(.none, value: value)
            }

            Spacer()
            trailing()
        }
    }

    // MARK: - Warning button（未設定項目）

    private func warningButton(icon: String, text: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.bold))
                        Text(text)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.orange)
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.orange.opacity(0.8))
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange.opacity(0.7))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - ES BOX section

    private var esBoxSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack(alignment: .center) {
                Text("ES BOX")
                    .font(.headline)

                Text("\(viewModel.esBoxesArray.count)件")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                Button { showESBoxCreate = true } label: {
                    Label("新規作成", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
            }

            if viewModel.esBoxesArray.isEmpty {
                emptyESBoxView
            } else {
                ForEach(viewModel.esBoxesArray) { esBox in
                    NavigationLink(value: esBox) {
                        ESBoxCard(esBox: esBox)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyESBoxView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 38))
                .foregroundStyle(.tertiary)
            Text("ES BOXがまだありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("「新規作成」から選考フェーズを追加してください")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Interview section

    private var interviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("面接予定")
                    .font(.headline)

                Text("\(viewModel.interviewsArray.count)件")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                Button { showInterviewCreate = true } label: {
                    Label("追加", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .tint(.red)
            }

            if viewModel.interviewsArray.isEmpty {
                emptyInterviewView
            } else {
                ForEach(viewModel.interviewsArray, id: \.objectID) { interview in
                    InterviewCard(
                        interview:      interview,
                        onEdit: {
                            editingInterview = interview
                            showEditInterview = true
                        },
                        onDelete:       { viewModel.deleteInterview(interview, in: context) },
                        onStatusChange: { viewModel.updateInterviewStatus(interview, status: $0, in: context) }
                    )
                }
            }
        }
    }

    private var emptyInterviewView: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2")
                .font(.system(size: 38))
                .foregroundStyle(.tertiary)
            Text("面接予定はまだありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("「追加」から面接の予定を登録してください")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Toolbar placement

    private var editButtonPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}

// MARK: - ES BOX Card（表示専用）

struct ESBoxCard: View {
    @ObservedObject var esBox: ESBox

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "ja_JP")
        f.dateStyle  = .medium
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 4)
                .padding(.vertical, 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(esBox.title ?? "タイトルなし")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let deadline = esBox.deadlineAt {
                        Label(Self.dateFormatter.string(from: deadline), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Text(esBox.status ?? "未着手")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor.opacity(0.12))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusColor: Color {
        (esBox.status ?? "未着手").esBoxStatusColor
    }
}

// MARK: - Interview Card

struct InterviewCard: View {
    @ObservedObject var interview: Interview

    let onEdit:         () -> Void
    let onDelete:       () -> Void
    let onStatusChange: (String) -> Void

    private static let statuses = ["予定", "通過", "落選", "辞退"]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale    = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        let status = interview.status ?? "予定"
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(status.interviewStatusColor)
                .frame(width: 4)
                .padding(.vertical, 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(interview.stage ?? "未定")
                        .font(.subheadline.weight(.semibold))

                    if let d = interview.startAt {
                        Label(Self.dateFormatter.string(from: d), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(interview.mode ?? "未定")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                statusMenuView(current: status)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contextMenu {
            Button { onEdit() } label: {
                Label("編集", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private func statusMenuView(current: String) -> some View {
        Menu {
            ForEach(Self.statuses, id: \.self) { s in
                Button {
                    onStatusChange(s)
                } label: {
                    if s == current {
                        Label(s, systemImage: "checkmark")
                    } else {
                        Text(s)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(current)
                    .font(.caption.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(current.interviewStatusColor.opacity(0.12))
            .foregroundStyle(current.interviewStatusColor)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    let ctx = PersistenceController.preview.context
    let company = (try? Company.fetchAll(in: ctx))?.first(where: { $0.name == "Apple" })
             ?? Company(context: ctx)
    return NavigationStack {
        CompanyDetailView(company: company)
    }
    .environment(\.managedObjectContext, ctx)
}
#endif
