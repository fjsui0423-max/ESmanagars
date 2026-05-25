import SwiftUI
import CoreData
import Combine

@MainActor
final class ESEditorViewModel: ObservableObject {

    let question: ESQuestion
    private let context: NSManagedObjectContext

    // MARK: - Published state

    @Published var answer: String
    @Published var saveState: SaveState = .idle

    enum SaveState: Equatable { case idle, saving, saved }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private var idleResetTask: Task<Void, Never>?

    // MARK: - Init

    init(question: ESQuestion, context: NSManagedObjectContext) {
        self.question = question
        self.context  = context
        self.answer   = question.currentAnswer ?? ""
        setupAutoSave()
    }

    // MARK: - Computed

    var progress: Double {
        let max = Int(question.maxLength)
        guard max > 0 else { return 0 }
        return Double(answer.count) / Double(max)
    }

    var versionsArray: [ESVersion] { question.versionsArray }

    // MARK: - Auto-save (debounce 1.5 s)

    private func setupAutoSave() {
        $answer
            .dropFirst()                                           // 初期値を無視
            .debounce(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.performSave() }
            .store(in: &cancellables)
    }

    // MARK: - Save actions

    /// アプリがバックグラウンドに移行した時に呼ぶ強制保存
    func forceSave() {
        guard question.currentAnswer != answer else { return }
        question.currentAnswer = answer
        try? context.save()
    }

    // MARK: - Version management

    /// 現在の内容を ESVersion としてスナップショット保存（最大5件を維持）
    func createSnapshot() {
        let version = ESVersion(context: context)
        version.id          = UUID()
        version.savedAnswer = answer
        version.createdAt   = Date()
        version.esQuestion  = question
        try? context.save()

        // 古いバージョンを剪定（最新5件のみ保持）
        let all = question.versionsArray           // createdAt 降順（新しい順）
        if all.count > 5 {
            all.dropFirst(5).forEach { context.delete($0) }
            try? context.save()
        }
    }

    // MARK: - Editor actions

    /// テンプレートや任意のテキストを末尾に挿入
    func insertText(_ text: String) {
        answer = answer.isEmpty ? text : answer + "\n\n" + text
    }

    /// 過去バージョンの内容でエディタを上書き（デバウンス後に自動保存される）
    func restoreVersion(_ version: ESVersion) {
        answer = version.savedAnswer ?? ""
    }

    /// 設問文と文字数制限を更新して保存する
    func updateQuestion(text: String, maxLength: Int16) {
        question.questionText = text
        question.maxLength    = maxLength
        objectWillChange.send()
        try? context.save()
    }

    // MARK: - Private helpers

    private func performSave() {
        guard question.currentAnswer != answer else { return }
        saveState = .saving
        question.currentAnswer = answer
        if let box = question.esBox, box.status == "未着手" {
            box.status = "進行中"
        }
        try? context.save()
        saveState = .saved

        idleResetTask?.cancel()
        idleResetTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { saveState = .idle }
        }
    }
}
