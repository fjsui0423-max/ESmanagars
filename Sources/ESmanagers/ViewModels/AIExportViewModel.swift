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
    添付したファイルは、私が過去に作成・提出したエントリーシート（ES）の設問と回答の記録です。

    このデータを読み込み、以下の点を分析・学習してください。

    1. 私のこれまでの経験やエピソード（学生時代・アルバイト・課外活動など）
    2. 私の強み、価値観、人柄
    3. 私の文章の書き方、トーン、表現の癖

    分析が完了したら「学習が完了しました。新しい設問を入力してください。」と返答してください。その後、私が新しい企業の設問を入力したときに、この過去のデータを参考にした最適な回答案を提案し、文章のブラッシュアップをサポートしてください。
    """

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - File generation

    func generateESDataFile() -> URL? {
        let boxes    = fetchBoxes()
        let markdown = buildMarkdown(from: boxes)
        let fileName = onlyPassed ? "ES_Data_Passed.md" : "ES_Data_All.md"
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
        let fmt = DateFormatter()
        fmt.locale    = Locale(identifier: "ja_JP")
        fmt.dateStyle = .medium
        fmt.timeStyle = .short

        var lines: [String] = [
            "# 過去のエントリーシート（ES）データ",
            "",
            "- エクスポート日時: \(fmt.string(from: Date()))",
            "- 抽出条件: \(onlyPassed ? "合格ESのみ（内定・インターン参加・ES通過）" : "提出済みES全件")",
            "- 件数: \(boxes.count)件",
            "",
            "---",
            "",
        ]

        guard !boxes.isEmpty else {
            lines.append("※ 条件に合うESデータがありませんでした。")
            return lines.joined(separator: "\n")
        }

        let sorted = boxes.sorted {
            let c0 = $0.selection?.company?.name ?? ""
            let c1 = $1.selection?.company?.name ?? ""
            guard c0 == c1 else { return c0 < c1 }
            return ($0.selection?.title ?? "") < ($1.selection?.title ?? "")
        }

        var lastCompany:   String? = nil
        var lastSelection: String? = nil

        for box in sorted {
            let company   = box.selection?.company?.name ?? "不明"
            let selTitle  = box.selection?.title    ?? "選考"
            let selCat    = box.selection?.category ?? ""
            let boxTitle  = box.title  ?? "ES"
            let boxStatus = box.status ?? ""

            if company != lastCompany {
                if lastCompany != nil { lines.append("") }
                lines += ["## \(company)", ""]
                lastCompany   = company
                lastSelection = nil
            }

            if selTitle != lastSelection {
                lines += ["### \(selTitle)（\(selCat)）", ""]
                lastSelection = selTitle
            }

            lines += ["#### 【\(boxTitle)】ステータス: \(boxStatus)", ""]

            let questions = box.questionsArray
            if questions.isEmpty {
                lines += ["※ 設問・回答データなし", ""]
            } else {
                for (i, q) in questions.enumerated() {
                    let qText  = q.questionText ?? "（設問テキストなし）"
                    let answer = (q.currentAnswer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let maxLen = q.maxLength > 0 ? "（最大\(q.maxLength)字）" : ""

                    lines += [
                        "**Q\(i + 1). \(qText)\(maxLen)**",
                        "",
                        answer.isEmpty ? "（回答なし）" : answer,
                        "",
                    ]
                }
            }

            lines += ["---", ""]
        }

        return lines.joined(separator: "\n")
    }
}
