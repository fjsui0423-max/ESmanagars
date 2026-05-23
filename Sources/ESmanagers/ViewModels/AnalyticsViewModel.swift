import CoreData
import SwiftUI

// MARK: - Data models

struct SelectionSummaryData {
    let total:    Int
    let achieved: Int
    var rate: Double { total > 0 ? Double(achieved) / Double(total) : 0 }
    static let empty = SelectionSummaryData(total: 0, achieved: 0)
}

struct ESStatsData {
    let total:      Int
    let inProgress: Int   // 未着手 + 進行中
    let overdue:    Int   // 提出遅れ（期限切れ）
    let submitted:  Int   // 提出済み（結果待ち）
    let passed:     Int   // 合格
    let failed:     Int   // 落選

    // MARK: 提出率 = (提出済み + 合格 + 落選) / 全ES数
    var submittedCount:  Int    { submitted + passed + failed }
    var submissionRate:  Double { total > 0 ? Double(submittedCount) / Double(total) : 0 }

    // MARK: 通過率 = 合格 / (合格 + 落選)
    var decidedCount: Int    { passed + failed }
    var passRate:     Double? { decidedCount > 0 ? Double(passed) / Double(decidedCount) : nil }

    // MARK: 提出率バー用（全ES中の比率）
    var inProgressBarRate: Double { total > 0 ? Double(inProgress)    / Double(total) : 0 }
    var overdueBarRate:    Double { total > 0 ? Double(overdue)       / Double(total) : 0 }
    var submittedBarRate:  Double { total > 0 ? Double(submittedCount) / Double(total) : 0 }

    // MARK: 通過率バー用（提出済みES中の比率）
    var passRateBarPassed:  Double { submittedCount > 0 ? Double(passed)    / Double(submittedCount) : 0 }
    var passRateBarFailed:  Double { submittedCount > 0 ? Double(failed)    / Double(submittedCount) : 0 }
    var passRateBarPending: Double { submittedCount > 0 ? Double(submitted) / Double(submittedCount) : 0 }

    static let empty = ESStatsData(total: 0, inProgress: 0, overdue: 0, submitted: 0, passed: 0, failed: 0)
}

struct AptitudeStatsData {
    let total:   Int
    let untaken: Int   // 未受験
    let taken:   Int   // 受験済み
    let passed:  Int   // 合格
    let failed:  Int   // 落選

    var decidedCount: Int     { passed + failed }
    var passRate:     Double? { decidedCount > 0 ? Double(passed) / Double(decidedCount) : nil }

    var untakenRate: Double { total > 0 ? Double(untaken) / Double(total) : 0 }
    var takenRate:   Double { total > 0 ? Double(taken)   / Double(total) : 0 }
    var passedRate:  Double { total > 0 ? Double(passed)  / Double(total) : 0 }
    var failedRate:  Double { total > 0 ? Double(failed)  / Double(total) : 0 }

    static let empty = AptitudeStatsData(total: 0, untaken: 0, taken: 0, passed: 0, failed: 0)
}

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

    var resultPassRate: Double? {
        let decided = passed + failed
        guard decided > 0 else { return nil }
        return Double(passed) / Double(decided)
    }
}

// MARK: - ViewModel

@MainActor
final class AnalyticsViewModel: ObservableObject {

    // MARK: - Filter state

    @Published var selectionCategoryFilter: String = "全て" {
        didSet { recompute() }
    }
    @Published var interviewModeFilter: String = "全て" {
        didSet { recompute() }
    }

    // MARK: - Computed outputs

    @Published var selectionSummary: SelectionSummaryData = .empty
    @Published var esStats:          ESStatsData          = .empty
    @Published var aptitudeStats:    AptitudeStatsData    = .empty
    @Published var stageStats:       [StageStats]         = []
    @Published var totalInterviews:  Int                  = 0

    // MARK: - Constants

    static let categoryFilters: [String] = ["全て", "インターン", "本選考"]
    static let modeFilters:     [String] = ["全て", "オンライン", "対面"]

    static let orderedStages: [String] = [
        "カジュアル面談", "1次面接", "2次面接", "3次面接", "最終面接"
    ]

    // MARK: - Raw data

    private var allSelections:    [Selection]    = []
    private var allInterviews:    [Interview]    = []
    private var allBoxes:         [ESBox]        = []
    private var allAptitudeTests: [AptitudeTest] = []
    private let context: NSManagedObjectContext

    // MARK: - Computed helpers

    var isNoData: Bool {
        allSelections.isEmpty && allInterviews.isEmpty &&
        allBoxes.isEmpty && allAptitudeTests.isEmpty
    }

    var summaryAchievedLabel: String {
        switch selectionCategoryFilter {
        case "インターン": return "参加数"
        case "本選考":    return "内定数"
        default:         return "合格数"
        }
    }

    var summaryRateLabel: String {
        switch selectionCategoryFilter {
        case "インターン": return "参加率"
        case "本選考":    return "内定率"
        default:         return "合格率"
        }
    }

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
        fetch()
    }

    // MARK: - Fetch

    func fetch() {
        allSelections    = (try? context.fetch(Selection.fetchRequest()))     ?? []
        allInterviews    = (try? context.fetch(Interview.fetchRequest()))     ?? []
        allBoxes         = (try? context.fetch(ESBox.fetchRequest()))         ?? []
        allAptitudeTests = (try? context.fetch(AptitudeTest.fetchRequest()))  ?? []
        recompute()
    }

    // MARK: - Recompute

    func recompute() {
        // 1. Filter selections by category
        let filteredSels: [Selection]
        switch selectionCategoryFilter {
        case "インターン": filteredSels = allSelections.filter { $0.category == "インターン" }
        case "本選考":    filteredSels = allSelections.filter { $0.category == "本選考" }
        default:         filteredSels = allSelections
        }
        let selIDs = Set(filteredSels.map { $0.objectID })

        // 2. Selection summary
        let achieved: Int
        switch selectionCategoryFilter {
        case "インターン":
            achieved = filteredSels.filter { $0.status == "インターン参加" }.count
        case "本選考":
            achieved = filteredSels.filter { $0.status == "内定" }.count
        default:
            achieved = filteredSels.filter {
                $0.status == "内定" || $0.status == "インターン参加"
            }.count
        }
        selectionSummary = SelectionSummaryData(total: filteredSels.count, achieved: achieved)

        // 3. Filter interviews by selection + mode
        var interviews = allInterviews.filter {
            guard let sid = $0.selection?.objectID else { return false }
            return selIDs.contains(sid)
        }
        if interviewModeFilter != "全て" {
            interviews = interviews.filter { $0.mode == interviewModeFilter }
        }
        totalInterviews = interviews.count

        // 4. Stage stats
        var result: [StageStats] = []
        for stage in Self.orderedStages {
            let group = interviews.filter { $0.stage == stage }
            if !group.isEmpty { result.append(makeStageStats(stage: stage, from: group)) }
        }
        let handled = Set(Self.orderedStages)
        let others  = Set(interviews.compactMap { $0.stage }).subtracting(handled).sorted()
        for stage in others {
            let group = interviews.filter { $0.stage == stage }
            result.append(makeStageStats(stage: stage, from: group))
        }
        stageStats = result

        // 5. ES stats
        //    提出率の分子 = 提出済み + 合格 + 落選
        //    通過率の分母 = 合格 + 落選（結果確定分のみ）
        let boxes = allBoxes.filter {
            guard let sid = $0.selection?.objectID else { return false }
            return selIDs.contains(sid)
        }
        esStats = ESStatsData(
            total:      boxes.count,
            inProgress: boxes.filter { ["未着手", "進行中"].contains($0.status ?? "") }.count,
            overdue:    boxes.filter { $0.status == "提出遅れ" }.count,
            submitted:  boxes.filter { $0.status == "提出済み" }.count,
            passed:     boxes.filter { $0.status == "合格" }.count,
            failed:     boxes.filter { $0.status == "落選" }.count
        )

        // 6. Aptitude stats
        let tests = allAptitudeTests.filter {
            guard let sid = $0.selection?.objectID else { return false }
            return selIDs.contains(sid)
        }
        aptitudeStats = AptitudeStatsData(
            total:   tests.count,
            untaken: tests.filter { $0.status == "未受験" }.count,
            taken:   tests.filter { $0.status == "受験済み" }.count,
            passed:  tests.filter { $0.status == "合格" }.count,
            failed:  tests.filter { $0.status == "落選" }.count
        )
    }

    // MARK: - Private

    private func makeStageStats(stage: String, from interviews: [Interview]) -> StageStats {
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
