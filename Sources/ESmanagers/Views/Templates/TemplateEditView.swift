import SwiftUI
import CoreData

// MARK: - Container

struct TemplateEditContainerView: View {
    @Environment(\.managedObjectContext) private var context
    let template: Template?
    var body: some View {
        TemplateEditView(template: template, context: context)
    }
}

// MARK: - Edit view

struct TemplateEditView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: TemplateViewModel

    let template: Template?

    // Fields
    @State private var title: String
    @State private var content: String
    @State private var selectedCategory: String
    @State private var newCategoryText: String = ""
    @State private var isAddingNewCategory: Bool
    @FocusState private var isContentFocused: Bool

    init(template: Template?, context: NSManagedObjectContext) {
        self.template = template
        _viewModel = StateObject(wrappedValue: TemplateViewModel(context: context))
        _title    = State(initialValue: template?.title    ?? "")
        _content  = State(initialValue: template?.content  ?? "")
        let cat = template?.category ?? ""
        _selectedCategory     = State(initialValue: cat.isEmpty ? "" : cat)
        _isAddingNewCategory  = State(initialValue: false)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                categorySection
                Section("タイトル") {
                    TextField("例：自己PR（300字）", text: $title)
                }
                Section {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("テンプレート本文を入力...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $content)
                            .focused($isContentFocused)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                    }
                } header: {
                    HStack {
                        Text("本文")
                        Spacer()
                        Text("\(content.count) 文字")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle(template == nil ? "テンプレートを追加" : "テンプレートを編集")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: cancelPlacement) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: savePlacement) {
                    Button("保存") { saveAndDismiss() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
                #if os(iOS)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isContentFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
                #endif
            }
        }
    }

    // MARK: - Category section

    @ViewBuilder
    private var categorySection: some View {
        Section("カテゴリ") {
            if !viewModel.allCategories.isEmpty {
                Toggle("新しいカテゴリを作成", isOn: $isAddingNewCategory)
                    .onChange(of: isAddingNewCategory) { adding in
                        if !adding { newCategoryText = "" }
                    }
            }

            if isAddingNewCategory || viewModel.allCategories.isEmpty {
                TextField("カテゴリ名を入力", text: $newCategoryText)
            } else {
                Picker("カテゴリ", selection: $selectedCategory) {
                    Text("なし").tag("")
                    ForEach(viewModel.allCategories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var resolvedCategory: String {
        if isAddingNewCategory || viewModel.allCategories.isEmpty {
            return newCategoryText.trimmingCharacters(in: .whitespaces)
        }
        return selectedCategory
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveAndDismiss() {
        viewModel.save(
            template: template,
            title: title,
            content: content,
            category: resolvedCategory
        )
        dismiss()
    }

    private var cancelPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarLeading
        #else
        .cancellationAction
        #endif
    }

    private var savePlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .confirmationAction
        #endif
    }
}

// MARK: - Preview

#if os(iOS)
#Preview("新規") {
    let ctx = PersistenceController.preview.context
    return TemplateEditContainerView(template: nil)
        .environment(\.managedObjectContext, ctx)
}

#Preview("編集") {
    let ctx = PersistenceController.preview.context
    let req = Template.fetchRequest()
    let t = (try? ctx.fetch(req))?.first
    return TemplateEditContainerView(template: t)
        .environment(\.managedObjectContext, ctx)
}
#endif
