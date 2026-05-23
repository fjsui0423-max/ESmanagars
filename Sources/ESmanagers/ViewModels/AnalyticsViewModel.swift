import CoreData
import SwiftUI

// MARK: - Data model

struct StageStats: Identifiable {
    let id         = UUID()
    let stage:     String
    let total:     Int
    let passed:    Int   // 通過
    let failed:    Int   // 落選
    let withdrawn: Int   // 辞退
    let scheduled: Int   // 予定

    var passRate:      Double { total > 0 ? Double(passed)    / Double(total) : 0 }
    var failRate:      Double { total > 0 ? Double(failed)    / Double(total) : 0 }
    var withdrawRate:  Double { total > 0 ? Double(withdrawn) / Double(total) : 0 }
    var scheduledRate: Double { total > 0 ? Double(scheduled) / Double(total) : 0 }

    // 結果確定分のみの通過率
    var resultPassRate: Double? {
        let resultCount = passed + failed
        guard resultCount > 0 else { return nil }
        return Double(passed) / Double(resultCount)
    }
}

// MARK: - ViewModel

@MainActor
final class AnalyticsViewModel: ObservableObject {

    @Published var stageStats:      [StageStats] = []
    @Published var totalInterviews: Int    = 0
    @Published var overallPassRate: Double = 0
    @Published var hasAnyResult:    Bool   = false

    private let context: NSManagedObjectContext

    static let orderedStages: [String] = [
        "カジュアル面談", "1次面接", "2次面接", "3次面接", "最終面接"
    ]

    init(context: NSManagedObjectContext) {
        self.context = context
        fetch()
    }

    // MARK: - Fetch

    func fetch() {
        let req = Interview.fetchRequest()
        let all = (try? context.fetch(req)) ?? []
        totalInterviews = all.count

        var result: [StageStats] = []

        for stage in Self.orderedStages {
            let group = all.filter { $0.stage == stage }
            if !group.isEmpty { result.append(makeStats(stage: stage, from: group)) }
        }

        // 未知のステージ（将来の拡張に対応）
        let handled = Set(Self.orderedStages)
        let others  = Set(all.compactMap { $0.stage }).subtracting(handled).sorted()
        for stage in others {
            let group = all.filter { $0.stage == stage }
            result.append(makeStats(stage: stage, from: group))
        }

        stageStats = result

        let withResult  = all.filter { $0.status == "通過" || $0.status == "落選" }.count
        let passedCount = all.filter { $0.status == "通過" }.count
        hasAnyResult    = withResult > 0
        overallPassRate = withResult > 0 ? Double(passedCount) / Double(withResult) : 0
    }

    // MARK: - Private

    private func makeStats(stage: String, from interviews: [Interview]) -> StageStats {
        StageStats(
            stage:     stage,
            total:     interviews.count,
            passed:    interviews.filter { $0.status == "通過" }.count,
            failed:    interviews.filter { $0.status == "落選" }.count,
            withdrawn: interviews.filter { $0.status == "辞退" }.count,
            scheduled: interviews.filter { $0.status == "予定" }.count
        )
    }
}
