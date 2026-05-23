import SwiftUI

struct SelectionCreateView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String) -> Void

    @State private var category = Selection.categories[0]
    @State private var title    = ""

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
            .navigationTitle("選考を追加")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: cancelPlacement) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: savePlacement) {
                    Button("追加") {
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
    SelectionCreateView { category, title in
        print("category: \(category), title: \(title)")
    }
}
#endif
