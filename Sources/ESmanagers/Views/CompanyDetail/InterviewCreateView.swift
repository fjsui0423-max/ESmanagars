import SwiftUI

struct InterviewCreateView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, Date, String) -> Void

    @State private var stage   = "1次面接"
    @State private var startAt = Date()
    @State private var mode    = "オンライン"

    static let stages: [String] = ["カジュアル面談", "1次面接", "2次面接", "3次面接", "最終面接"]
    static let modes:  [String] = ["オンライン", "対面"]

    var body: some View {
        NavigationStack {
            Form {
                Section("選考フェーズ") {
                    Picker("フェーズ", selection: $stage) {
                        ForEach(Self.stages, id: \.self) { Text($0) }
                    }
                }

                Section("面接日時") {
                    DatePicker(
                        "日時",
                        selection: $startAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("実施形式") {
                    Picker("形式", selection: $mode) {
                        ForEach(Self.modes, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("面接を追加")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: cancelPlacement) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: savePlacement) {
                    Button("保存") {
                        onSave(stage, startAt, mode)
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

// MARK: - Preview

#if os(iOS)
#Preview {
    InterviewCreateView { stage, date, mode in
        print("stage: \(stage), date: \(date), mode: \(mode)")
    }
}
#endif
