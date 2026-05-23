import SwiftUI
import CoreData

struct HomeView: View {

    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Industry.sortOrder, ascending: true)],
        animation: .default
    )
    private var industries: FetchedResults<Industry>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Company.name, ascending: true)],
        predicate: NSPredicate(format: "industry == nil"),
        animation: .default
    )
    private var standaloneCompanies: FetchedResults<Company>

    @StateObject private var viewModel: HomeViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    // MARK: - + ボタン用ステート
    @State private var showAddMenu          = false
    @State private var showAddCompanyAlert  = false
    @State private var showAddIndustryAlert = false
    @State private var newItemName          = ""

    // MARK: - ドラッグ&ドロップ用ステート（企業同士）
    @State private var dropTargetedID:       UUID?
    @State private var pendingSourceID:      UUID?
    @State private var pendingTargetCompany: Company?
    @State private var showFolderNameAlert   = false
    @State private var newFolderName         = ""

    // MARK: - ドラッグ&ドロップ用ステート（既存フォルダ）
    @State private var folderDropTargetedID: UUID?

    // MARK: - 削除確認用ステート
    @State private var pendingDeleteCompany:      Company?
    @State private var pendingDeleteIndustry:     Industry?
    @State private var showDeleteCompanyConfirm  = false
    @State private var showDeleteIndustryConfirm = false

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: context))
    }

    // MARK: - Body

    var body: some View {
        mainContent
            .alert(
                "企業を削除",
                isPresented: $showDeleteCompanyConfirm,
                presenting: pendingDeleteCompany
            ) { company in
                Button("削除", role: .destructive) {
                    viewModel.deleteCompany(company)
                    pendingDeleteCompany = nil
                }
                Button("キャンセル", role: .cancel) { pendingDeleteCompany = nil }
            } message: { company in
                Text("「\(company.name ?? "")」を削除します。関連するESデータもすべて削除されます。この操作は取り消せません。")
            }
            .alert(
                "フォルダを削除",
                isPresented: $showDeleteIndustryConfirm,
                presenting: pendingDeleteIndustry
            ) { industry in
                Button("削除", role: .destructive) {
                    viewModel.deleteIndustry(industry)
                    pendingDeleteIndustry = nil
                }
                Button("キャンセル", role: .cancel) { pendingDeleteIndustry = nil }
            } message: { industry in
                Text("「\(industry.name ?? "")」を削除します。フォルダ内の企業・関連するすべてのデータが削除されます。この操作は取り消せません。")
            }
    }

    private var mainContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(industries) { industry in
                    industryFolderItem(industry)
                }
                ForEach(standaloneCompanies) { company in
                    companyGridItem(company)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("企業・業界一覧")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .background(gridBackground)
        .toolbar {
            ToolbarItem(placement: toolbarPlacement) {
                Button { showAddMenu = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // ---- NavigationLink(value:) の宛先登録 ----
        .navigationDestination(for: Company.self) { company in
            CompanyDetailView(company: company)
        }
        // ---- + ボタン: 追加メニュー ----
        .confirmationDialog("追加する項目を選択", isPresented: $showAddMenu, titleVisibility: .visible) {
            Button("企業を追加")           { showAddCompanyAlert  = true }
            Button("フォルダ（業界）を追加") { showAddIndustryAlert = true }
            Button("キャンセル", role: .cancel) {}
        }
        // ---- 企業名入力アラート ----
        .alert("企業を追加", isPresented: $showAddCompanyAlert) {
            TextField("企業名（例: Apple）", text: $newItemName)
            Button("追加") {
                viewModel.addCompany(name: newItemName)
                newItemName = ""
            }
            Button("キャンセル", role: .cancel) { newItemName = "" }
        }
        // ---- フォルダ名入力アラート ----
        .alert("フォルダを追加", isPresented: $showAddIndustryAlert) {
            TextField("フォルダ名（例: IT・通信）", text: $newItemName)
            Button("追加") {
                viewModel.addIndustry(name: newItemName)
                newItemName = ""
            }
            Button("キャンセル", role: .cancel) { newItemName = "" }
        }
        // ---- D&D: フォルダ作成アラート ----
        .alert("フォルダ名を入力", isPresented: $showFolderNameAlert) {
            TextField("フォルダ名（例: IT・通信）", text: $newFolderName)
            Button("作成") {
                if let sourceID = pendingSourceID,
                   let target   = pendingTargetCompany {
                    viewModel.createFolderAndGroup(
                        name:     newFolderName,
                        sourceID: sourceID,
                        target:   target
                    )
                }
                resetDropState()
            }
            Button("キャンセル", role: .cancel) { resetDropState() }
        } message: {
            Text("ドラッグした2つの企業を同じフォルダにまとめます")
        }
    }

    // MARK: - Industry フォルダアイテム（ドロップ対応）

    @ViewBuilder
    private func industryFolderItem(_ industry: Industry) -> some View {
        let isTargeted = folderDropTargetedID == industry.id

        IndustryFolderView(industry: industry)
            .overlay(alignment: .center) {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 3)
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(isTargeted ? 1.08 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isTargeted)
            .contextMenu {
                Button(role: .destructive) {
                    pendingDeleteIndustry = industry
                    showDeleteIndustryConfirm = true
                } label: {
                    Label("このフォルダを削除", systemImage: "trash")
                }
            }
            // 企業UUIDをドロップ → 既存フォルダに移動
            .dropDestination(for: String.self) { items, _ in
                guard let uuidString = items.first,
                      let sourceID   = UUID(uuidString: uuidString) else { return false }
                viewModel.moveCompany(sourceID: sourceID, to: industry)
                return true
            } isTargeted: { targeted in
                folderDropTargetedID = targeted ? industry.id : nil
            }
    }

    // MARK: - Company グリッドアイテム

    @ViewBuilder
    private func companyGridItem(_ company: Company) -> some View {
        let isTargeted = dropTargetedID == company.id

        NavigationLink(value: company) {
            CompanyIconView(company: company)
                .overlay(alignment: .center) {
                    if isTargeted {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                            .allowsHitTesting(false)
                    }
                }
                .scaleEffect(isTargeted ? 1.06 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isTargeted)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                pendingDeleteCompany = company
                showDeleteCompanyConfirm = true
            } label: {
                Label("この企業を削除", systemImage: "trash")
            }
        }
        // ドラッグ元: 企業UUIDを文字列として提供
        .draggable(company.id?.uuidString ?? "")
        // ドロップ先: 同企業へのドロップは無視、異なる企業でフォルダ作成
        .dropDestination(for: String.self) { items, _ in
            guard let uuidString = items.first,
                  let sourceID   = UUID(uuidString: uuidString),
                  sourceID       != company.id else { return false }
            pendingSourceID      = sourceID
            pendingTargetCompany = company
            newFolderName        = ""
            showFolderNameAlert  = true
            return true
        } isTargeted: { targeted in
            dropTargetedID = targeted ? company.id : nil
        }
    }

    // MARK: - Helpers

    private func resetDropState() {
        pendingSourceID      = nil
        pendingTargetCompany = nil
        newFolderName        = ""
    }

    private var gridBackground: some View {
        #if os(iOS)
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        #else
        Color(NSColor.windowBackgroundColor).ignoresSafeArea()
        #endif
    }

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}

// MARK: - Container

struct HomeViewContainer: View {
    @Environment(\.managedObjectContext) private var context
    var body: some View {
        HomeView(context: context)
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    NavigationStack {
        HomeViewContainer()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.context)
}
#endif
