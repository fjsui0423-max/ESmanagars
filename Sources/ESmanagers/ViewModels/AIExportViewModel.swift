import CoreData
import SwiftUI

@MainActor
final class AIExportViewModel: ObservableObject {

    // MARK: - Published state

    @Published var onlyPassed:  Bool   = true
    @Published var isExporting: Bool   = false
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext

    // MARK: - Value-type relay structs（CoreData オブジェクトをバックグラウンドに渡すための中継）

    private struct MappedBox: Sendable {
        let company:   String
        let title:     String
        let category:  String
        let status:    String
        let questions: [MappedQuestion]
    }

    private struct MappedQuestion: Sendable {
        let text:   String
        let answer: String
        let limit:  Int16
    }

    // MARK: - AI Prompt

    let aiPrompt: String = """
    あなたはプロのキャリアコンサルタントであり、私の専属のエントリーシート（ES）作成アシスタントです。

    添付したテキストファイルには、私が過去に作成し、実際の企業の選考に提出したESの設問と回答の履歴データがまとめられています。

    まずはこの添付ファイルを注意深く読み込み、私の「経験（学生時代に力を入れたことなど）」「強み」「価値観」、および「文章のトーンや構成力」を深く学習・分析してください。

    今後の会話では、私が新しく指定する企業の設問に対して、この過去の経験や成功パターンを最大限に活かした最適な回答案の作成、構成の提案、または私が書いた文章のブラッシュアップを行ってください。
    一般的な就活のテンプレートに当てはめるのではなく、「私ならではの具体的なエピソード」をファイルから適切に引き出し、説得力のある回答を構築することがあなたの最も重要な役割です。

    ファイルの読み込みと分析が完了したら、私のアピールポイントの要約を箇条書きで短く提示した上で、「過去のESデータの読み込みと分析が完了しました。次に作成したい企業の名前と、新しい設問（文字数制限など）を教えてください。」と返答し、私からの次の指示を待機してください。
    """

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - File generation（非同期・スレッドセーフ）

    func generateESDataFile() async -> URL? {
        isExporting = true
        defer { isExporting = false }

        // UI を一度描画させるための短いスリープ
        try? await Task.sleep(nanoseconds: 100_000_000)

        // ① メインスレッドで CoreData を読み取り、値型にマッピング
        let mappedBoxes = fetchAndMapBoxes()
        let fileName = onlyPassed ? "My_ES_Data_Passed.md" : "My_ES_Data_All.md"

        // ② バックグラウンドでファイル文字列を構築して書き出す
        let result: Result<URL, Error> = await Task.detached(priority: .userInitiated) {
            let markdown = Self.buildMarkdown(from: mappedBoxes)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
            do {
                try markdown.write(to: url, atomically: true, encoding: .utf8)
                return .success(url)
            } catch {
                return .failure(error)
            }
        }.value

        switch result {
        case .success(let url):
            return url
        case .failure(let error):
            errorMessage = "ファイルの生成に失敗しました: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Private: fetch + map（必ずメインスレッドで呼ぶこと）

    private func fetchAndMapBoxes() -> [MappedBox] {
        guard let all = try? context.fetch(ESBox.fetchRequest()) else { return [] }

        let filtered: [ESBox]
        if onlyPassed {
            filtered = all.filter {
                $0.status == "合格"
                    || $0.selection?.status == "内定"
                    || $0.selection?.status == "インターン参加"
            }
        } else {
            let submitted: Set<String> = ["提出済み", "合格", "落選", "提出遅れ"]
            filtered = all.filter { submitted.contains($0.status ?? "") }
        }

        return filtered.map { box in
            MappedBox(
                company:   box.selection?.company?.name ?? "不明",
                title:     box.selection?.title         ?? "",
                category:  box.selection?.category      ?? "",
                status:    box.status                   ?? "",
                questions: box.questionsArray.map { q in
                    MappedQuestion(
                        text:   q.questionText  ?? "（設問テキストなし）",
                        answer: q.currentAnswer ?? "",
                        limit:  q.maxLength
                    )
                }
            )
        }
    }

    // MARK: - Private: Markdown 構築（static → Task.detached から安全に呼べる）

    private nonisolated static func buildMarkdown(from boxes: [MappedBox]) -> String {
        guard !boxes.isEmpty else {
            return "※ 条件に合うESデータがありませんでした。"
        }

        let sorted = boxes.sorted {
            guard $0.company == $1.company else { return $0.company < $1.company }
            return $0.title < $1.title
        }

        var blocks: [String] = []

        for box in sorted {
            var lines: [String] = [
                "# 企業名: \(box.company)",
                "- 選考ルート: \(box.category)",
                "- 結果: \(box.status)",
                "",
            ]

            if box.questions.isEmpty {
                lines += ["※ 設問・回答データなし", ""]
            } else {
                for q in box.questions {
                    let answer = q.answer.trimmingCharacters(in: .whitespacesAndNewlines)
                    let limit  = q.limit > 0 ? " (制限: \(q.limit)文字)" : ""
                    lines += [
                        "## 設問: \(q.text)\(limit)",
                        answer.isEmpty ? "（回答なし）" : answer,
                        "",
                    ]
                }
            }

            blocks.append(lines.joined(separator: "\n"))
        }

        return blocks.joined(separator: "---\n\n")
    }
}
