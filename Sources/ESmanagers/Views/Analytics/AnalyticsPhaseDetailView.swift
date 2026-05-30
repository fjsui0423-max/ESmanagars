import SwiftUI
import CoreData

/// フェーズ別の合否企業一覧画面
struct AnalyticsPhaseDetailView: View {
    @Environment(\.managedObjectContext) private var context

    let phase: AnalyticsPhase
    @ObservedObject var viewModel: AnalyticsViewModel

    // Computed once per render — avoids redundant calls
    private var results: (passed: [Company], failed: [Company]) {
        viewModel.getCompanyResults(for: phase)
    }

    var body: some View {
        List {
            passedSection
            failedSection

            // タブバー・下部バナーへの被りを防ぐ余白
            Color.clear
                .frame(height: 80)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(titleForPhase)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(Color.systemGroupedBackground.ignoresSafeArea())
    }

    // MARK: - Passed section

    private var passedSection: some View {
        Section {
            if results.passed.isEmpty {
                Text("該当する企業がありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(results.passed) { company in
                    NavigationLink {
                        CompanyDetailView(company: company)
                            .environment(\.managedObjectContext, context)
                    } label: {
                        companyRow(company, color: .green)
                    }
                }
            }
        } header: {
            Label(passedLabel, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } footer: {
            if !results.passed.isEmpty {
                Text("\(results.passed.count)社")
            }
        }
    }

    // MARK: - Failed section

    private var failedSection: some View {
        Section {
            if results.failed.isEmpty {
                Text("該当する企業がありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(results.failed) { company in
                    NavigationLink {
                        CompanyDetailView(company: company)
                            .environment(\.managedObjectContext, context)
                    } label: {
                        companyRow(company, color: .red)
                    }
                }
            }
        } header: {
            Label("落選", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        } footer: {
            if !results.failed.isEmpty {
                Text("\(results.failed.count)社")
            }
        }
    }

    // MARK: - Company row

    private func companyRow(_ company: Company, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(String(company.name?.prefix(1) ?? "?"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(company.name ?? "名称未設定")
                    .font(.subheadline.weight(.semibold))
                if let industryName = company.industry?.name, !industryName.isEmpty {
                    Text(industryName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var titleForPhase: String {
        switch phase {
        case .es:
            return "ES 詳細"
        case .interview(let stage):
            return "\(stage) 詳細"
        case .aptitude(let type):
            return type.map { "\($0) 詳細" } ?? "適性検査 詳細"
        }
    }

    /// フェーズによって「通過」か「合格」の表記を切り替え
    private var passedLabel: String {
        switch phase {
        case .interview: return "通過"
        default:         return "合格"
        }
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    NavigationStack {
        AnalyticsPhaseDetailView(
            phase:     .es,
            viewModel: AnalyticsViewModel(context: PersistenceController.preview.context)
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.context)
}
#endif
