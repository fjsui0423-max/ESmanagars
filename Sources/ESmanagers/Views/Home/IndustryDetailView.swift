import SwiftUI
import CoreData

struct IndustryDetailView: View {
    @ObservedObject var industry: Industry

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        Group {
            if industry.companiesArray.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(industry.companiesArray) { company in
                            NavigationLink(value: company) {
                                CompanyIconView(company: company)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle(industry.name ?? "フォルダ")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .background(Color.systemGroupedBackground.ignoresSafeArea())
        .navigationDestination(for: Company.self) { company in
            CompanyDetailView(company: company)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("企業がまだありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("ホーム画面から企業をドラッグしてフォルダに追加できます")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
