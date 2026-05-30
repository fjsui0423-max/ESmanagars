import SwiftUI
import CoreData

/// フェーズ・ステータス別の企業一覧画面
struct AnalyticsDetailView: View {
    @Environment(\.managedObjectContext) private var context

    let title:     String
    let companies: [Company]

    var body: some View {
        Group {
            if companies.isEmpty {
                emptyState
            } else {
                companyList
            }
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(Color.systemGroupedBackground.ignoresSafeArea())
    }

    // MARK: - Company list

    private var companyList: some View {
        List {
            Section {
                ForEach(companies) { company in
                    NavigationLink {
                        CompanyDetailView(company: company)
                            .environment(\.managedObjectContext, context)
                    } label: {
                        companyRow(company)
                    }
                }
            } footer: {
                Text("\(companies.count)社")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // タブバー・下部バナーへの被りを防ぐ余白
            Color.clear
                .frame(height: 80)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Company row

    private func companyRow(_ company: Company) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(String(company.name?.prefix(1) ?? "?"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)
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

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "building.2.slash")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("該当する企業がありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    NavigationStack {
        AnalyticsDetailView(title: "ES - 合格", companies: [])
    }
    .environment(\.managedObjectContext, PersistenceController.preview.context)
}
#endif
