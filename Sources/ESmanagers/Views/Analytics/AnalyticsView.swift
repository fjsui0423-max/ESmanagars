import SwiftUI
import CoreData

// MARK: - Container

struct AnalyticsContainerView: View {
    @Environment(\.managedObjectContext) private var context
    var body: some View {
        AnalyticsView(context: context)
    }
}

// MARK: - Main view

struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isNoData {
                    emptyState
                } else {
                    summaryCard
                    if viewModel.esStats.total > 0 {
                        esStatsCard
                    }
                    if viewModel.aptitudeStats.total > 0 {
                        aptitudeStatsCard
                    }
                    if !viewModel.stageStats.isEmpty {
                        interviewSection
                        legendCard
                    } else if viewModel.totalInterviews == 0 && !viewModel.isNoData {
                        noInterviewPlaceholder
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 20)
        }
        .background(Color.systemGroupedBackground.ignoresSafeArea())
        .navigationTitle("分析")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .safeAreaInset(edge: .top, spacing: 0) {
            filterStrip
        }
        .onAppear { viewModel.fetch() }
    }

    // MARK: - Filter strip

    private var filterStrip: some View {
        VStack(spacing: 8) {
            Picker("カテゴリ", selection: $viewModel.selectionCategoryFilter) {
                ForEach(AnalyticsViewModel.categoryFilters, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                Image(systemName: "person.2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("形式", selection: $viewModel.interviewModeFilter) {
                    ForEach(AnalyticsViewModel.modeFilters, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        HStack(spacing: 0) {
            kpiCell(
                value: "\(viewModel.selectionSummary.total)",
                unit: "件",
                label: "総選考数",
                color: .primary
            )

            Divider().frame(height: 56).padding(.horizontal, 4)

            kpiCell(
                value: "\(viewModel.selectionSummary.achieved)",
                unit: "件",
                label: viewModel.summaryAchievedLabel,
                color: viewModel.selectionSummary.achieved > 0 ? .green : .secondary
            )

            Divider().frame(height: 56).padding(.horizontal, 4)

            kpiCell(
                value: viewModel.selectionSummary.total > 0
                    ? "\(Int(viewModel.selectionSummary.rate * 100))"
                    : "—",
                unit: viewModel.selectionSummary.total > 0 ? "%" : "",
                label: viewModel.summaryRateLabel,
                color: rateColor(viewModel.selectionSummary.rate,
                                 hasData: viewModel.selectionSummary.total > 0)
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func kpiCell(value: String, unit: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(color.opacity(0.7))
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func rateColor(_ rate: Double, hasData: Bool) -> Color {
        guard hasData else { return .secondary }
        if rate >= 0.5 { return .green }
        if rate >= 0.25 { return .orange }
        return .red
    }

    // MARK: - ES stats card

    private var esStatsCard: some View {
        let s = viewModel.esStats
        return VStack(alignment: .leading, spacing: 12) {
            Label("ES提出状況", systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundStyle(Color.blue)

            HStack(alignment: .top, spacing: 0) {
                // Left panel — submission rate (5-segment bar)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ES提出率")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("全ES: \(s.total)件")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            barSegment(color: .blue,              rate: s.submittedBarRate,     width: geo.size.width)
                            barSegment(color: .orange,            rate: s.submittedLateBarRate, width: geo.size.width)
                            barSegment(color: .gray.opacity(0.2), rate: s.noDeadlineBarRate,    width: geo.size.width)
                            barSegment(color: .gray.opacity(0.4), rate: s.notSubmittedBarRate,  width: geo.size.width)
                            barSegment(color: .red,               rate: s.expiredBarRate,       width: geo.size.width)
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 22)

                    Text("\(Int(s.submissionRate * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.blue)

                    Text("期限内提出: \(s.totalSubmitted)件")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let detail = esUnsubmittedDetail(s) {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider().padding(.horizontal, 12)

                // Right panel — pass rate (結果確定分のみ)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("通過率")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("期限内提出: \(s.totalSubmitted)件")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if s.resultCount > 0 {
                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                barSegment(color: .green, rate: s.passRateBarPassed, width: geo.size.width)
                                barSegment(color: .red,   rate: s.passRateBarFailed, width: geo.size.width)
                            }
                            .clipShape(Capsule())
                        }
                        .frame(height: 22)

                        Text("\(Int(s.passRate * 100))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.green)

                        HStack(spacing: 6) {
                            if s.passed > 0 { countBadge(s.passed, "合格", .green) }
                            if s.failed > 0 { countBadge(s.failed, "落選", .red) }
                        }
                    } else {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 22)
                        Text("—")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    if s.waitingCount > 0 {
                        Text("※ 結果待ち: \(s.waitingCount)件")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func esUnsubmittedDetail(_ s: ESStatsData) -> String? {
        let parts: [String] = [
            s.submittedLate > 0 ? "提出遅れ: \(s.submittedLate)件" : nil,
            s.notSubmitted  > 0 ? "未提出: \(s.notSubmitted)件"    : nil,
            s.expired       > 0 ? "期限切れ: \(s.expired)件"       : nil,
            s.noDeadline    > 0 ? "期限未設定: \(s.noDeadline)件"  : nil,
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    // MARK: - Aptitude stats card

    private var aptitudeStatsCard: some View {
        let s = viewModel.aptitudeStats
        return statsCard(
            title: "適性検査",
            systemImage: "checkmark.circle.fill",
            accentColor: .orange,
            total: s.total,
            subtitle: s.passRate.map { "合格率 \(Int($0 * 100))%（結果確定分）" }
        ) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    barSegment(color: .secondary.opacity(0.25), rate: s.untakenRate, width: geo.size.width)
                    barSegment(color: .blue,                    rate: s.takenRate,   width: geo.size.width)
                    barSegment(color: .green,                   rate: s.passedRate,  width: geo.size.width)
                    barSegment(color: .red,                     rate: s.failedRate,  width: geo.size.width)
                }
                .clipShape(Capsule())
            }
            .frame(height: 22)

            HStack(spacing: 8) {
                if s.untaken > 0 { countBadge(s.untaken, "未受験",  .secondary) }
                if s.taken   > 0 { countBadge(s.taken,   "受験済み", .blue) }
                if s.passed  > 0 { countBadge(s.passed,  "合格",    .green) }
                if s.failed  > 0 { countBadge(s.failed,  "落選",    .red) }
            }
        }
    }

    // MARK: - Shared stats card shell

    private func statsCard<Content: View>(
        title: String,
        systemImage: String,
        accentColor: Color,
        total: Int,
        subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                Spacer()
                Text("\(total)件")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            content()

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Interview section

    private var interviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("面接ステージ別")
                    .font(.headline)
                    .padding(.horizontal, 4)
                Spacer()
                if viewModel.interviewModeFilter != "全て" {
                    Text(viewModel.interviewModeFilter)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            ForEach(viewModel.stageStats) { stats in
                stageRow(stats)
            }
        }
    }

    private func stageRow(_ stats: StageStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Text(stats.stage)
                    .font(.subheadline.weight(.semibold))
                if let rate = stats.resultPassRate {
                    Text("通過率 \(Int(rate * 100))%")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("受験: \(stats.takenCount)件")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            if stats.takenCount > 0 {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        barSegment(color: .green,  rate: stats.passRateBar,     width: geo.size.width)
                        barSegment(color: .red,    rate: stats.failRateBar,     width: geo.size.width)
                        barSegment(color: .orange, rate: stats.withdrawRateBar, width: geo.size.width)
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 22)
            } else {
                Capsule()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 22)
            }

            if stats.passed > 0 || stats.failed > 0 || stats.withdrawn > 0 {
                HStack(spacing: 8) {
                    if stats.passed    > 0 { countBadge(stats.passed,    "通過", .green) }
                    if stats.failed    > 0 { countBadge(stats.failed,    "落選", .red) }
                    if stats.withdrawn > 0 { countBadge(stats.withdrawn, "辞退", .orange) }
                }
            }

            if stats.scheduled > 0 {
                Text("※ 予定: \(stats.scheduled)件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Legend

    private var legendCard: some View {
        HStack(spacing: 0) {
            ForEach(
                [("通過", Color.green), ("落選", Color.red), ("辞退", Color.orange)],
                id: \.0
            ) { label, color in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 14, height: 8)
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - No interview placeholder

    private var noInterviewPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("このフィルタ条件では面接データがありません")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("まだデータがありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("企業詳細から選考・面接を登録すると\n通過・内定の傾向を分析できます")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Shared helpers

    @ViewBuilder
    private func barSegment(color: Color, rate: Double, width: CGFloat) -> some View {
        if rate > 0 {
            color.frame(width: width * CGFloat(rate))
        }
    }

    private func countBadge(_ count: Int, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text("\(label) \(count)件")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    NavigationStack {
        AnalyticsContainerView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.context)
}
#endif
