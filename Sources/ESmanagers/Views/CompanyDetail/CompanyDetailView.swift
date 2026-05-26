import SwiftUI
import CoreData

struct CompanyDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.openURL)             private var openURL

    @StateObject private var viewModel: CompanyDetailViewModel

    @State private var showEditSheet       = false
    @State private var targetSelection:    Selection? = nil
    @State private var showAddSelection    = false
    @State private var showAddESBox        = false
    @State private var showAddAptitudeTest = false
    @State private var showAddInterview    = false
    @State private var editingInterview:   Interview? = nil
    @State private var showEditInterview   = false

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
                    Image(systemName: "pencil").fontWeight(.medium)
                }
            }
        }
        .navigationDestination(for: ESBox.self) { esBox in
            ESBoxDetailView(esBox: esBox)
        }
        .sheet(isPresented: $showEditSheet, onDismiss: { viewModel.refreshCompanyData() }) {
            CompanyEditView(company: viewModel.company)
                .environment(\.managedObjectContext, context)
        }
        .sheet(isPresented: $showAddSelection) {
            SelectionCreateView { category, title in
                viewModel.addSelection(category: category, title: title, in: context)
            }
        }
        .sheet(isPresented: $showAddESBox) {
            ESBoxCreateView { title, deadline, offsets in
                if let sel = targetSelection {
                    viewModel.addESBox(to: sel, title: title, deadline: deadline,
                                       notifOffsets: offsets, in: context)
                }
                targetSelection = nil
            }
        }
        .sheet(isPresented: $showAddAptitudeTest) {
            AptitudeTestCreateView { type, customType, deadline, status, offsets in
                if let sel = targetSelection {
                    viewModel.addAptitudeTest(to: sel, type: type, customType: customType,
                                              deadline: deadline, status: status,
                                              notifOffsets: offsets, in: context)
                }
                targetSelection = nil
            }
        }
        .sheet(isPresented: $showAddInterview) {
            InterviewCreateView { stage, startAt, mode, offsets in
                if let sel = targetSelection {
                    viewModel.addInterview(to: sel, stage: stage, startAt: startAt, mode: mode,
                                          notifOffsets: offsets, in: context)
                }
                targetSelection = nil
            }
        }
        .sheet(isPresented: $showEditInterview) {
            if let interview = editingInterview {
                InterviewEditView(interview: interview) { stage, startAt, mode, offsets in
                    viewModel.updateInterview(interview, stage: stage, startAt: startAt, mode: mode,
                                             notifOffsets: offsets, in: context)
                }
            }
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                loginSupportCard
                selectionSection
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
            HStack {
                Label("ログイン情報", systemImage: "key.fill")
                    .font(.headline)
                Spacer()
                Button { showEditSheet = true } label: {
                    Label("編集", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(Color.accentColor)
            }

            Text("※ マイページボタンをタップするとログインIDをコピーして採用サイトを開きます")
                .font(.caption)
                .foregroundStyle(.secondary)

            urlSection
            Divider()
            loginIDSection
            Divider()

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
            warningButton(icon: "safari", text: "マイページURLが未設定です", hint: "タップして設定する") {
                showEditSheet = true
            }
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
                Button { viewModel.copyLoginID() } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        } else {
            warningButton(icon: "person.circle.fill", text: "ログインIDが未設定です", hint: "タップして設定する") {
                showEditSheet = true
            }
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
                    Button { Task { await viewModel.copyPassword() } } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                Button { Task { await viewModel.togglePasswordVisibility() } } label: {
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
        icon: String, label: String, value: String,
        isSet: Bool, monospaced: Bool = false,
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

    // MARK: - Warning button

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
                        Text(text).font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.orange)
                    Text(hint).font(.caption).foregroundStyle(.orange.opacity(0.8))
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

    // MARK: - Selection section

    private var selectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("選考")
                    .font(.headline)
                Text("\(viewModel.selectionsArray.count)件")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
                Spacer()
                Button { showAddSelection = true } label: {
                    Label("追加", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
            }

            if viewModel.selectionsArray.isEmpty {
                emptySelectionView
            } else {
                ForEach(viewModel.selectionsArray) { selection in
                    SelectionCard(
                        selection: selection,
                        onAddESBox: {
                            targetSelection = selection
                            showAddESBox = true
                        },
                        onAddAptitudeTest: {
                            targetSelection = selection
                            showAddAptitudeTest = true
                        },
                        onAddInterview: {
                            targetSelection = selection
                            showAddInterview = true
                        },
                        onEditInterview: { interview in
                            editingInterview = interview
                            showEditInterview = true
                        },
                        onDeleteInterview: { viewModel.deleteInterview($0, in: context) },
                        onInterviewStatusChange: { viewModel.updateInterviewStatus($0, status: $1, in: context) },
                        onAptitudeStatusChange: { viewModel.updateAptitudeTestStatus($0, status: $1, in: context) },
                        onDeleteAptitudeTest: { viewModel.deleteAptitudeTest($0, in: context) },
                        onSelectionStatusChange: { viewModel.updateSelectionStatus(selection, status: $0, in: context) },
                        onDeleteSelection: { viewModel.deleteSelection(selection, in: context) }
                    )
                }
            }
        }
    }

    private var emptySelectionView: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 38))
                .foregroundStyle(.tertiary)
            Text("選考がまだありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("「追加」からインターンや本選考を登録してください")
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

// MARK: - Selection Card

struct SelectionCard: View {
    @ObservedObject var selection: Selection

    let onAddESBox:              () -> Void
    let onAddAptitudeTest:       () -> Void
    let onAddInterview:          () -> Void
    let onEditInterview:         (Interview) -> Void
    let onDeleteInterview:       (Interview) -> Void
    let onInterviewStatusChange: (Interview, String) -> Void
    let onAptitudeStatusChange:  (AptitudeTest, String) -> Void
    let onDeleteAptitudeTest:    (AptitudeTest) -> Void
    let onSelectionStatusChange: (String) -> Void
    let onDeleteSelection:       () -> Void

    var body: some View {
        VStack(spacing: 0) {
            selectionHeader

            let boxes      = selection.esBoxesArray
            let aptitudes  = selection.aptitudeTestsArray
            let interviews = selection.interviewsArray
            let hasItems   = !boxes.isEmpty || !aptitudes.isEmpty || !interviews.isEmpty

            if hasItems {
                Divider().padding(.horizontal, 16)
            }

            if !boxes.isEmpty {
                itemSectionLabel("ES BOX", color: .blue)
                ForEach(boxes) { esBox in
                    NavigationLink(value: esBox) {
                        ESBoxRow(esBox: esBox)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                }
            }

            if !aptitudes.isEmpty {
                itemSectionLabel("適性検査", color: .orange)
                ForEach(aptitudes) { test in
                    AptitudeTestRow(
                        test: test,
                        onStatusChange: { onAptitudeStatusChange(test, $0) },
                        onDelete: { onDeleteAptitudeTest(test) }
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                }
            }

            if !interviews.isEmpty {
                itemSectionLabel("面接", color: .red)
                ForEach(interviews, id: \.objectID) { interview in
                    InterviewCard(
                        interview:      interview,
                        onEdit:         { onEditInterview(interview) },
                        onDelete:       { onDeleteInterview(interview) },
                        onStatusChange: { onInterviewStatusChange(interview, $0) }
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                }
            }

            Divider().padding(.horizontal, 16)
            addButtonsRow
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contextMenu {
            Button(role: .destructive, action: onDeleteSelection) {
                Label("この選考を削除", systemImage: "trash")
            }
        }
    }

    // MARK: - Header

    private var selectionHeader: some View {
        HStack(spacing: 10) {
            Text(selection.category ?? "選考")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(categoryColor.opacity(0.15))
                .foregroundStyle(categoryColor)
                .clipShape(Capsule())

            Text(selection.title ?? "未設定")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Spacer()

            selectionStatusMenu
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var categoryColor: Color {
        switch selection.category {
        case "インターン": return .teal
        case "本選考":    return .indigo
        default:         return .secondary
        }
    }

    private var selectionStatusMenu: some View {
        let status = selection.status ?? "進行中"
        return Menu {
            ForEach(Selection.statuses, id: \.self) { s in
                Button { onSelectionStatusChange(s) } label: {
                    if s == status { Label(s, systemImage: "checkmark") }
                    else { Text(s) }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(status).font(.caption.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(status.selectionStatusColor.opacity(0.12))
            .foregroundStyle(status.selectionStatusColor)
            .clipShape(Capsule())
        }
    }

    // MARK: - Section label

    private func itemSectionLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 2)
    }

    // MARK: - Add buttons

    private var addButtonsRow: some View {
        HStack(spacing: 8) {
            chipButton("ES", systemImage: "doc.text", color: .blue, action: onAddESBox)
            chipButton("適性検査", systemImage: "checkmark.circle", color: .orange, action: onAddAptitudeTest)
            chipButton("面接", systemImage: "person.2", color: .red, action: onAddInterview)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func chipButton(_ label: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage).font(.system(size: 11, weight: .semibold))
                Text(label).font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ES Box Row (inside SelectionCard)

struct ESBoxRow: View {
    @ObservedObject var esBox: ESBox

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale    = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        let status = esBox.status ?? "未着手"
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(status.esBoxStatusColor)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(esBox.title ?? "タイトルなし")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if let d = esBox.deadlineAt {
                    Label(Self.dateFormatter.string(from: d), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(status)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.esBoxStatusColor.opacity(0.12))
                .foregroundStyle(status.esBoxStatusColor)
                .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.tertiarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - AptitudeTest Row

struct AptitudeTestRow: View {
    @ObservedObject var test: AptitudeTest
    let onStatusChange: (String) -> Void
    let onDelete: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale    = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        let status = test.status ?? "未受験"
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(status.aptitudeStatusColor)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(test.displayType)
                    .font(.subheadline.weight(.semibold))
                if let d = test.deadlineAt {
                    Label(Self.dateFormatter.string(from: d), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Menu {
                ForEach(AptitudeTest.statuses, id: \.self) { s in
                    Button { onStatusChange(s) } label: {
                        if s == status { Label(s, systemImage: "checkmark") }
                        else { Text(s) }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(status).font(.caption.weight(.semibold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.aptitudeStatusColor.opacity(0.12))
                .foregroundStyle(status.aptitudeStatusColor)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.tertiarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("削除", systemImage: "trash")
            }
        }
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
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(status.interviewStatusColor)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(interview.stage ?? "未定")
                    .font(.subheadline.weight(.semibold))
                if let d = interview.startAt {
                    Label(Self.dateFormatter.string(from: d), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let mode = interview.mode, !mode.isEmpty {
                    Text(mode)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Menu {
                ForEach(Self.statuses, id: \.self) { s in
                    Button { onStatusChange(s) } label: {
                        if s == status { Label(s, systemImage: "checkmark") }
                        else { Text(s) }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(status).font(.caption.weight(.semibold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.interviewStatusColor.opacity(0.12))
                .foregroundStyle(status.interviewStatusColor)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.tertiarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            Button { onEdit() } label: { Label("編集", systemImage: "pencil") }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("削除", systemImage: "trash")
            }
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
