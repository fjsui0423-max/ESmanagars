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
                if viewModel.totalInterviews == 0 {
                    emptyState
                } else {
                    summaryCard
                    chartSection
                    legendCard
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
        .onAppear { viewModel.fetch() }
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        HStack(spacing: 0) {
            // 総面接数
            VStack(alignment: .leading, spacing: 4) {
                Text("総面接数")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.totalInterviews)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("件")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 60)
                .padding(.horizontal, 16)

            // 通過率
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.hasAnyResult ? "通過率" : "結果待ち")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if viewModel.hasAnyResult {
                    Text("\(Int(viewModel.overallPassRate * 100))")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.overallPassRate >= 0.5 ? Color.green : Color.red)
                    Text("%（結果確定分）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("—")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.tertiary)
                    Text("面接進行中")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Chart section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ステージ別結果")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(viewModel.stageStats) { stats in
                    stageRow(stats)
                }
            }
        }
    }

    private func stageRow(_ stats: StageStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(alignment: .center, spacing: 8) {
                Text(stats.stage)
                    .font(.subheadline.weight(.semibold))

                if let rate = stats.resultPassRate {
                    Text("通過率 \(Int(rate * 100))%")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(stats.total)件")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Stacked bar
            GeometryReader { geo in
                HStack(spacing: 0) {
                    if stats.passed > 0 {
                        Color.green
                            .frame(width: geo.size.width * CGFloat(stats.passRate))
                    }
                    if stats.failed > 0 {
                        Color.red
                            .frame(width: geo.size.width * CGFloat(stats.failRate))
                    }
                    if stats.withdrawn > 0 {
                        Color.orange
                            .frame(width: geo.size.width * CGFloat(stats.withdrawRate))
                    }
                    if stats.scheduled > 0 {
                        Color.secondary.opacity(0.2)
                            .frame(width: geo.size.width * CGFloat(stats.scheduledRate))
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: 24)

            // Count badges
            HStack(spacing: 8) {
                if stats.passed > 0 {
                    countBadge(count: stats.passed, label: "通過", color: .green)
                }
                if stats.failed > 0 {
                    countBadge(count: stats.failed, label: "落選", color: .red)
                }
                if stats.withdrawn > 0 {
                    countBadge(count: stats.withdrawn, label: "辞退", color: .orange)
                }
                if stats.scheduled > 0 {
                    countBadge(count: stats.scheduled, label: "予定", color: .secondary)
                }
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func countBadge(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text("\(label) \(count)件")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Legend

    private var legendCard: some View {
        HStack(spacing: 0) {
            ForEach(
                [("通過", Color.green), ("落選", Color.red),
                 ("辞退", Color.orange), ("予定", Color.secondary.opacity(0.5))],
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

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("まだ面接データがありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("企業詳細から面接を登録すると\n通過・落選の傾向を分析できます")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
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
