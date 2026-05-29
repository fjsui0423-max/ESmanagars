import SwiftUI

/// 既存の選考（Selection）のカテゴリ・タイトルを編集するシート
struct SelectionEditView: View {
    @Environment(\.dismiss) private var dismiss

    /// 書き換え後の (category, title) を呼び出し元に渡す
    let onSave: (String, String) -> Void

    @State private var category: String
    @State private var title:    String

    init(selection: Selection, onSave: @escaping (String, String) -> Void) {
        self.onSave = onSave
        _category = State(initialValue: selection.category ?? Selection.categories[0])
        _title    = State(initialValue: selection.title    ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("種別") {
                    Picker("種別", selection: $category) {
                        ForEach(Selection.categories, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("選考名") {
                    TextField("例：エンジニア本選考", text: $title)
                }
            }
            .navigationTitle("選考を編集")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: cancelPlacement) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: savePlacement) {
                    Button("保存") {
                        let t = title.trimmingCharacters(in: .whitespaces)
                        onSave(category, t.isEmpty ? category : t)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
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

#if os(iOS)
#Preview {
    let ctx = PersistenceController.preview.context
    let sel = Selection(context: ctx)
    sel.id       = UUID()
    sel.category = "本選考"
    sel.title    = "エンジニアコース"
    return SelectionEditView(selection: sel) { cat, title in
        print("category: \(cat), title: \(title)")
    }
}
#endif
