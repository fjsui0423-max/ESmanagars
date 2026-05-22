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

    // MARK: - Subviews

    private var templateList: some View {
        List {
            ForEach(viewModel.allCategories, id: \.self) { category in
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
            }
        }
        .listStyle(.insetGrouped)
    }

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
