import SwiftUI

struct AptitudeTestCreateView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String?, Date?, String) -> Void

    @State private var selectedType = AptitudeTest.types[0]
    @State private var customType   = ""
    @State private var hasDeadline  = false
    @State private var deadline     = Date()
    @State private var status       = AptitudeTest.statuses[0]

    var body: some View {
        NavigationStack {
            Form {
                Section("テスト種別") {
                    Picker("種別", selection: $selectedType) {
                        ForEach(AptitudeTest.types, id: \.self) { Text($0) }
                    }
                    if selectedType == "カスタム" {
                        TextField("種別名を入力", text: $customType)
                    }
                }

                Section {
                    Toggle("締切日を設定する", isOn: $hasDeadline.animation())
                    if hasDeadline {
                        DatePicker("締切日", selection: $deadline, displayedComponents: .date)
                    }
                }

                Section("ステータス") {
                    Picker("ステータス", selection: $status) {
                        ForEach(AptitudeTest.statuses, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("適性検査を追加")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: cancelPlacement) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: savePlacement) {
                    Button("追加") {
                        let custom = selectedType == "カスタム" ? customType.trimmingCharacters(in: .whitespaces) : nil
                        onSave(selectedType, custom, hasDeadline ? deadline : nil, status)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedType == "カスタム" && customType.trimmingCharacters(in: .whitespaces).isEmpty)
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
    AptitudeTestCreateView { type, custom, deadline, status in
        print("type: \(type), custom: \(String(describing: custom)), status: \(status)")
    }
}
#endif
