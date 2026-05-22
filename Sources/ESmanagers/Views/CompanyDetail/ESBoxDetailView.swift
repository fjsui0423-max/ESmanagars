import SwiftUI
import CoreData

struct ESBoxDetailView: View {
    let esBox: ESBox

    @FetchRequest private var questions: FetchedResults<ESQuestion>

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
        // ESQuestion → ESEditorContainerView への遷移先登録
        .navigationDestination(for: ESQuestion.self) { question in
            ESEditorContainerView(question: question)
        }
    }

    // MARK: - Deadline banner

    @ViewBuilder
    private var deadlineBanner: some View {
        if let deadline = esBox.deadlineAt {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                Text("締切：\(Self.dateFormatter.string(from: deadline))")
                    .font(.subheadline.weight(.medium))
                Spacer()
                let status = esBox.status ?? "未着手"
                Text(status)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(status.esBoxStatusColor.opacity(0.15))
                    .foregroundStyle(status.esBoxStatusColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
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
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("設問がまだありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("設問はアプリ管理者が追加します")
                .font(.caption)
                .foregroundStyle(.tertiary)
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
