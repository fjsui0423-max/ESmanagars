import SwiftUI
import CoreData

struct IndustryDetailView: View {
    @ObservedObject var industry: Industry
    @Environment(\.managedObjectContext) private var context

    @State private var pendingDeleteCompany:     Company?
    @State private var showDeleteCompanyConfirm = false

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
                            .contextMenu {
                                Button {
                                    company.industry = nil
                                    if context.hasChanges { try? context.save() }
                                } label: {
                                    Label("フォルダから出す", systemImage: "folder.badge.minus")
                                }

                                Button(role: .destructive) {
                                    pendingDeleteCompany    = company
                                    showDeleteCompanyConfirm = true
                                } label: {
                                    Label("この企業を削除", systemImage: "trash")
                                }
                            }
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
        .alert(
            "企業を削除",
            isPresented: $showDeleteCompanyConfirm,
            presenting: pendingDeleteCompany
        ) { company in
            Button("削除", role: .destructive) {
                context.delete(company)
                try? context.save()
                pendingDeleteCompany = nil
            }
            Button("キャンセル", role: .cancel) { pendingDeleteCompany = nil }
        } message: { company in
            Text("「\(company.name ?? "")」を削除します。関連するESデータもすべて削除されます。この操作は取り消せません。")
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
