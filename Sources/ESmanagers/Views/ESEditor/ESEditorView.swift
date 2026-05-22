import SwiftUI
import CoreData

// MARK: - Container（@Environment からコンテキストを受け取る）

struct ESEditorContainerView: View {
    let question: ESQuestion
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        ESEditorView(question: question, context: context)
    }
}

// MARK: - Main editor view

struct ESEditorView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel: ESEditorViewModel
    @FocusState  private var isEditorFocused: Bool

    @State private var isQuestionExpanded = false
    @State private var showTemplateSheet  = false
    @State private var showHistorySheet   = false

    init(question: ESQuestion, context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ESEditorViewModel(question: question, context: context))
    }

    var body: some View {
        VStack(spacing: 0) {
            questionAccordion
            Divider()
            characterCountBar
            Divider()
            textEditorArea
        }
        .navigationTitle("設問 \(viewModel.question.sortOrder + 1)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: trailingPlacement) { saveStateView }
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) { keyboardToolbarItems }
            #endif
        }
        .sheet(isPresented: $showTemplateSheet) {
            TemplatePickerView { content in
                viewModel.insertText(content)
                showTemplateSheet = false
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showHistorySheet) {
            VersionHistoryView(versions: viewModel.versionsArray) { version in
                viewModel.restoreVersion(version)
                showHistorySheet = false
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: scenePhase) { phase in          // iOS 16 互換の単一引数版
            if phase == .background { viewModel.forceSave() }
        }
    }

    // MARK: - Subviews

    /// 設問文アコーディオン
    private var questionAccordion: some View {
        DisclosureGroup(isExpanded: $isQuestionExpanded) {
            Text(viewModel.question.questionText ?? "設問文なし")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .padding(.bottom, 2)
        } label: {
            Label("設問を確認する", systemImage: "questionmark.circle.fill")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondarySystemGroupedBackground)
        .animation(.easeInOut(duration: 0.2), value: isQuestionExpanded)
    }

    /// 文字数カウンター & プログレスバー
    private var characterCountBar: some View {
        let maxLen = Int(viewModel.question.maxLength)
        let count  = viewModel.answer.count

        return VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                // 現在 / 上限
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(count)")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(progressColor)
                        .contentTransition(.numericText())
                    Text("/ \(maxLen > 0 ? "\(maxLen)" : "∞") 文字")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // 残り文字数
                if maxLen > 0 {
                    let remaining = maxLen - count
                    Text(remaining >= 0 ? "残り \(remaining) 文字" : "超過 \(abs(remaining)) 文字")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(remaining < 0 ? .red : .secondary)
                        .contentTransition(.numericText())
                }
            }
            // プログレスバー（上限設定時のみ）
            if maxLen > 0 {
                ProgressView(value: min(viewModel.progress, 1.0))
                    .tint(progressColor)
                    .animation(.easeInOut(duration: 0.15), value: viewModel.progress)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    /// TextEditor 本体
    private var textEditorArea: some View {
        TextEditor(text: $viewModel.answer)
            .focused($isEditorFocused)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.systemGroupedBackground)
    }

    // MARK: - Save state indicator

    @ViewBuilder
    private var saveStateView: some View {
        switch viewModel.saveState {
        case .idle:
            EmptyView()
        case .saving:
            HStack(spacing: 4) {
                ProgressView().scaleEffect(0.75)
                Text("保存中...").font(.caption).foregroundStyle(.secondary)
            }
        case .saved:
            Label("保存済み", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
                .transition(.opacity)
        }
    }

    // MARK: - Keyboard toolbar

    @ViewBuilder
    private var keyboardToolbarItems: some View {
        Button { showTemplateSheet = true } label: {
            Label("テンプレート", systemImage: "doc.text.fill")
        }
        Spacer()
        // 履歴ボタン：現在の内容をスナップショット保存してからシート表示
        Button {
            viewModel.createSnapshot()
            showHistorySheet = true
        } label: {
            Label("履歴", systemImage: "clock.arrow.circlepath")
        }
        Spacer()
        Button { isEditorFocused = false } label: {
            Image(systemName: "keyboard.chevron.compact.down")
        }
    }

    // MARK: - Helpers

    private var progressColor: Color {
        if viewModel.progress > 1.0 { return .red }
        if viewModel.progress > 0.8 { return .orange }
        return Color.accentColor
    }

    private var trailingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}

// MARK: - Template picker sheet

struct TemplatePickerView: View {
    @Environment(\.managedObjectContext) private var context
    let onSelect: (String) -> Void

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Template.category, ascending: true),
                          NSSortDescriptor(keyPath: \Template.title,    ascending: true)]
    )
    private var templates: FetchedResults<Template>

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    emptyState(icon: "doc.text",
                               title: "テンプレートがありません",
                               desc: "テンプレート機能は今後追加されます")
                } else {
                    List(templates) { template in
                        Button { onSelect(template.content ?? "") } label: {
                            templateRow(template)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("テンプレートを選択")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func templateRow(_ t: Template) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(t.title ?? "無題").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Spacer()
                if let cat = t.category.nilIfEmpty {
                    Text(cat).font(.caption).padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor).clipShape(Capsule())
                }
            }
            Text(t.content ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Version history sheet

struct VersionHistoryView: View {
    let versions: [ESVersion]
    let onRestore: (ESVersion) -> Void

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if versions.isEmpty {
                    emptyState(icon: "clock.arrow.circlepath",
                               title: "履歴がありません",
                               desc: "「履歴」ボタンを押すと現在の内容が保存されます")
                } else {
                    List {
                        ForEach(versions) { version in
                            Button { onRestore(version) } label: { versionRow(version) }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("履歴から復元")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func versionRow(_ v: ESVersion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            let text = v.savedAnswer ?? ""
            Text(text.isEmpty ? "（空の回答）" : text)
                .font(.subheadline)
                .foregroundStyle(text.isEmpty ? .tertiary : .primary)
                .lineLimit(3)
            if let date = v.createdAt {
                Text(Self.formatter.string(from: date))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Shared empty state helper

private func emptyState(icon: String, title: String, desc: String) -> some View {
    VStack(spacing: 12) {
        Image(systemName: icon).font(.system(size: 44)).foregroundStyle(.tertiary)
        Text(title).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
        Text(desc).font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
}

// MARK: - Preview

#if os(iOS)
#Preview {
    let ctx = PersistenceController.preview.context
    let req = NSFetchRequest<ESQuestion>(entityName: "ESQuestion")
    let question: ESQuestion
    if let q = try? ctx.fetch(req), let first = q.first {
        question = first
    } else {
        let q = ESQuestion(context: ctx)
        q.id = UUID(); q.sortOrder = 0; q.maxLength = 400
        q.questionText = "自己PRを400字以内で教えてください。"
        q.currentAnswer = ""
        question = q
    }
    return NavigationStack {
        ESEditorContainerView(question: question)
    }
    .environment(\.managedObjectContext, ctx)
}
#endif
