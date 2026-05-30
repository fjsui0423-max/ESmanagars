import SwiftUI
import CoreData

// MARK: - Container

struct TemplateListContainerView: View {
    @Environment(\.managedObjectContext) private var context
    var body: some View {
        TemplateListView(context: context)
    }
}

// MARK: - Main list

struct TemplateListView: View {
    @StateObject private var viewModel: TemplateViewModel
    @State private var showAdd = false
    @State private var editingTemplate: Template?

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TemplateViewModel(context: context))
    }

    var body: some View {
        Group {
            if viewModel.groupedTemplates.isEmpty {
                emptyState
            } else {
                templateList
            }
        }
        .navigationTitle("テンプレート")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: addButtonPlacement) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd, onDismiss: viewModel.fetch) {
            TemplateEditContainerView(template: nil)
        }
        .sheet(item: $editingTemplate, onDismiss: viewModel.fetch) { t in
            TemplateEditContainerView(template: t)
        }
    }

    // MARK: - Template list

    private var templateList: some View {
        List {
            // インフィード広告: カテゴリの「間」に挟む（index == 0 の直後、以降3つおき）
            ForEach(Array(viewModel.allCategories.enumerated()), id: \.element) { index, category in

                // ① 通常のテンプレートカテゴリセクション
                Section(header: Text(category)) {
                    ForEach(viewModel.groupedTemplates[category] ?? []) { template in
                        Button { editingTemplate = template } label: {
                            templateRow(template)
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete { offsets in
                        viewModel.delete(category: category, at: offsets)
                    }
                }

                // ② インフィード広告セクション（最初のカテゴリ直後、以降3つおき）
                if index == 0 || (index > 0 && index % 3 == 0) {
                    Section {
                        HStack {
                            Spacer()
                            AdMobLargeBannerView()
                                .frame(width: 300, height: 250)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                }
            }

            // ★ リスト最下部の安全余白（タブバー・下部バナーへの被りを防ぐ）
            Color.clear
                .frame(height: 100)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Template row

    private func templateRow(_ t: Template) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(t.title ?? "無題")
                .font(.subheadline.weight(.semibold))
            Text(t.content ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("テンプレートがありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("右上の＋ボタンから追加できます")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button {
                showAdd = true
            } label: {
                Label("テンプレートを追加", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var addButtonPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    let ctx = PersistenceController.preview.context
    return NavigationStack {
        TemplateListView(context: ctx)
    }
    .environment(\.managedObjectContext, ctx)
}
#endif
