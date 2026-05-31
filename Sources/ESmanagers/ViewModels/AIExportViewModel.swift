import CoreData
import SwiftUI

@MainActor
final class AIExportViewModel: ObservableObject {

    // MARK: - Published state

    @Published var onlyPassed:   Bool   = true
    @Published var isExporting:  Bool   = false
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext

    // MARK: - Codable + Sendable export structs

    private struct ExportData: Codable, Sendable {
        let company:           String
        let selectionCategory: String
        let result:            String
        let questions:         [ExportQuestion]
    }

    private struct ExportQuestion: Codable, Sendable {
        let question: String
        let answer:   String
        let limit:    Int16?   // nil = 制限なし
    }

    // MARK: - AI Prompt

    let aiPrompt: String = """
    あなたはプロのキャリアコンサルタントであり、私の専属のエントリーシート（ES）作成アシスタントです。

    添付したJSONファイルには、私が過去に作成し、実際の企業の選考に提出したESの設問と回答の履歴データがまとめられています。

    まずはこの添付ファイルを注意深く読み込み、私の「経験（学生時代に力を入れたことなど）」「強み」「価値観」、および「文章のトーンや構成力」を深く学習・分析してください。

    今後の会話では、私が新しく指定する企業の設問に対して、この過去の経験や成功パターンを最大限に活かした最適な回答案の作成、構成の提案、または私が書いた文章のブラッシュアップを行ってください。
    一般的な就活のテンプレートに当てはめるのではなく、「私ならではの具体的なエピソード」をファイルから適切に引き出し、説得力のある回答を構築することがあなたの最も重要な役割です。

    ファイルの読み込みと分析が完了したら、私のアピールポイントの要約を箇条書きで短く提示した上で、「過去のESデータの読み込みと分析が完了しました。次に作成したい企業の名前と、新しい設問（文字数制限など）を教えてください。」と返答し、私からの次の指示を待機してください。
    """

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - File generation（非同期・スレッドセーフ・JSON出力）

    func generateESDataFile() async -> URL? {
        isExporting = true
        defer { isExporting = false }

        // UI を一度描画させるための短いスリープ
        try? await Task.sleep(nanoseconds: 100_000_000)

        // ① メインスレッドで CoreData を読み取り、Codable 値型にマッピング
        let exportItems = fetchAndMapBoxes()
        let fileName    = onlyPassed ? "My_ES_Data_Passed.json" : "My_ES_Data_All.json"

        // ② バックグラウンドで JSON エンコード → ファイル書き出し
        let result: Result<URL, Error> = await Task.detached(priority: .userInitiated) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
            do {
                let data = try encoder.encode(exportItems)
                try data.write(to: url, options: .atomic)
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

    private func fetchAndMapBoxes() -> [ExportData] {
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

        // 企業名 → 選考タイトルの順でソート
        let sorted = filtered.sorted {
            let c0 = $0.selection?.company?.name ?? ""
            let c1 = $1.selection?.company?.name ?? ""
            guard c0 == c1 else { return c0 < c1 }
            return ($0.selection?.title ?? "") < ($1.selection?.title ?? "")
        }

        return sorted.compactMap { box -> ExportData? in
            // 回答済みの設問のみ抽出（空回答は除外してトークンを節約）
            let questions: [ExportQuestion] = box.questionsArray.compactMap { q in
                let answer = (q.currentAnswer ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !answer.isEmpty else { return nil }
                return ExportQuestion(
                    question: q.questionText ?? "（設問テキストなし）",
                    answer:   answer,
                    limit:    q.maxLength > 0 ? q.maxLength : nil
                )
            }
            // 設問がひとつもないBoxは出力しない
            guard !questions.isEmpty else { return nil }

            return ExportData(
                company:           box.selection?.company?.name ?? "不明",
                selectionCategory: box.selection?.category      ?? "",
                result:            box.status                   ?? "",
                questions:         questions
            )
        }
    }
}
