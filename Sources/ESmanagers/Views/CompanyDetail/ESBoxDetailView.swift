import SwiftUI
import CoreData

struct ESBoxDetailView: View {
    @Environment(\.managedObjectContext) private var context

    @ObservedObject var esBox: ESBox

    @FetchRequest private var questions: FetchedResults<ESQuestion>

    @State private var showAddQuestion = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale    = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        return f
    }()

    init(esBox: ESBox) {
        self.esBox = esBox
        let req = ESQuestion.fetchRequest()
        req.predicate      = NSPredicate(format: "esBox == %@", esBox)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \ESQuestion.sortOrder, ascending: true)]
        _questions = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
        Group {
            if questions.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(questions, id: \.objectID) { question in
                        NavigationLink(value: question) {
                            questionRow(question)
                        }
                    }
                    .onDelete(perform: deleteQuestions)
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.systemGroupedBackground.ignoresSafeArea())
        .navigationTitle(esBox.title ?? "ES詳細")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .safeAreaInset(edge: .top) { deadlineBanner }
        .toolbar {
            ToolbarItem(placement: addButtonPlacement) {
                Button {
                    showAddQuestion = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // ESQuestion → ESEditorContainerView への遷移先登録
        .navigationDestination(for: ESQuestion.self) { question in
            ESEditorContainerView(question: question)
        }
        .sheet(isPresented: $showAddQuestion) {
            ESQuestionCreateView { text, max in
                addQuestion(text: text, maxLength: max)
            }
        }
    }

    // MARK: - Add question

    private func deleteQuestions(at offsets: IndexSet) {
        offsets.map { questions[$0] }.forEach { context.delete($0) }
        try? context.save()
    }

    private func addQuestion(text: String, maxLength: Int16) {
        let q = ESQuestion(context: context)
        q.id           = UUID()
        q.questionText = text
        q.maxLength    = maxLength
        q.currentAnswer = ""
        q.sortOrder    = Int16(questions.count)
        q.esBox        = esBox
        try? context.save()
    }

    private var addButtonPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }

    // MARK: - Deadline banner

    private var deadlineBanner: some View {
        HStack(spacing: 8) {
            if let deadline = esBox.deadlineAt {
                Image(systemName: "calendar.badge.clock")
                Text("締切：\(Self.dateFormatter.string(from: deadline))")
                    .font(.subheadline.weight(.medium))
            }
            Spacer()
            statusMenu
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private static let statuses = ["未着手", "進行中", "提出済み", "提出遅れ", "合格", "落選"]

    private var statusMenu: some View {
        let current = esBox.status ?? "進行中"
        return Menu {
            ForEach(Self.statuses, id: \.self) { s in
                Button {
                    esBox.status = s
                    try? context.save()
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
            .padding(.vertical, 4)
            .background(current.esBoxStatusColor.opacity(0.15))
            .foregroundStyle(current.esBoxStatusColor)
            .clipShape(Capsule())
        }
    }

    // MARK: - Question row

    private func questionRow(_ q: ESQuestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("設問 \(Int(q.sortOrder) + 1)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)

            Text(q.questionText ?? "（設問文なし）")
                .font(.subheadline)
                .foregroundStyle(q.questionText.nilIfEmpty != nil ? Color.primary : Color.secondary)
                .lineLimit(2)

            let count = (q.currentAnswer ?? "").count
            let max   = Int(q.maxLength)
            HStack(spacing: 8) {
                Text(max > 0 ? "\(count) / \(max) 文字" : "\(count) 文字")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(max > 0 && count > max ? Color.red : Color.secondary)
                if max > 0 {
                    ProgressView(value: min(Double(count) / Double(max), 1.0))
                        .tint(max > 0 && count > max ? .red : Color.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("設問がまだありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("右上の ＋ ボタンから設問を追加してください")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    let ctx = PersistenceController.preview.context
    let req = ESBox.fetchRequest()
    let esBox = (try? ctx.fetch(req))?.first ?? ESBox(context: ctx)
    return NavigationStack {
        ESBoxDetailView(esBox: esBox)
    }
    .environment(\.managedObjectContext, ctx)
}
#endif
