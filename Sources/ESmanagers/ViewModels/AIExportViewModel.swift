import CoreData
import SwiftUI

@MainActor
final class AIExportViewModel: ObservableObject {

    // MARK: - Filter state

    @Published var onlyPassed: Bool = true
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext

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

    // MARK: - File generation

    func generateESDataFile() -> URL? {
        let boxes    = fetchBoxes()
        let markdown = buildMarkdown(from: boxes)
        let fileName = onlyPassed ? "My_ES_Data_Passed.md" : "My_ES_Data_All.md"
        let url      = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            errorMessage = "ファイルの生成に失敗しました: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Private

    private func fetchBoxes() -> [ESBox] {
        guard let all = try? context.fetch(ESBox.fetchRequest()) else { return [] }
        if onlyPassed {
            return all.filter {
                $0.status == "合格"
                    || $0.selection?.status == "内定"
                    || $0.selection?.status == "インターン参加"
            }
        }
        let submitted: Set<String> = ["提出済み", "合格", "落選", "提出遅れ"]
        return all.filter { submitted.contains($0.status ?? "") }
    }

    private func buildMarkdown(from boxes: [ESBox]) -> String {
        guard !boxes.isEmpty else {
            return "※ 条件に合うESデータがありませんでした。"
        }

        let sorted = boxes.sorted {
            let c0 = $0.selection?.company?.name ?? ""
            let c1 = $1.selection?.company?.name ?? ""
            guard c0 == c1 else { return c0 < c1 }
            return ($0.selection?.title ?? "") < ($1.selection?.title ?? "")
        }

        var blocks: [String] = []

        for box in sorted {
            let company   = box.selection?.company?.name ?? "不明"
            let selCat    = box.selection?.category      ?? ""
            let boxStatus = box.status                   ?? ""

            var lines: [String] = [
                "# 企業名: \(company)",
                "- 選考ルート: \(selCat)",
                "- 結果: \(boxStatus)",
                "",
            ]

            let questions = box.questionsArray
            if questions.isEmpty {
                lines += ["※ 設問・回答データなし", ""]
            } else {
                for q in questions {
                    let qText  = q.questionText ?? "（設問テキストなし）"
                    let answer = (q.currentAnswer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let limit  = q.maxLength > 0 ? " (制限: \(q.maxLength)文字)" : ""

                    lines += [
                        "## 設問: \(qText)\(limit)",
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
