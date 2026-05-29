import SwiftUI

/// 既存の適性検査（AptitudeTest）の種別・締切日・ステータスを編集するシート
struct AptitudeTestEditView: View {
    @Environment(\.dismiss) private var dismiss

    /// 書き換え後の (type, customType, deadline, status, notifOffsets) を呼び出し元に渡す
    let onSave: (String, String?, Date?, String, Set<DeadlineOffset>) -> Void

    @State private var selectedType: String
    @State private var customType:   String
    @State private var hasDeadline:  Bool
    @State private var deadline:     Date
    @State private var status:       String
    @State private var notifOffsets: Set<DeadlineOffset>

    init(test: AptitudeTest, onSave: @escaping (String, String?, Date?, String, Set<DeadlineOffset>) -> Void) {
        self.onSave = onSave
        let currentType = test.type ?? AptitudeTest.types[0]
        _selectedType = State(initialValue: currentType)
        _customType   = State(initialValue: test.customType ?? "")
        _hasDeadline  = State(initialValue: test.deadlineAt != nil)
        _deadline     = State(initialValue: test.deadlineAt ?? Date())
        _status       = State(initialValue: test.status     ?? AptitudeTest.statuses[0])
        let saved: Set<DeadlineOffset>
        if let id = test.id?.uuidString {
            saved = NotificationManager.shared.savedDeadlineOffsets(for: id)
        } else {
            saved = [.oneDay]
        }
        _notifOffsets = State(initialValue: saved)
    }

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

                if hasDeadline {
                    DeadlineNotificationSection(selectedOffsets: $notifOffsets)
                }
            }
            .navigationTitle("適性検査を編集")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: cancelPlacement) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: savePlacement) {
                    Button("保存") {
                        let custom = selectedType == "カスタム"
                            ? customType.trimmingCharacters(in: .whitespaces)
                            : nil
                        onSave(selectedType, custom, hasDeadline ? deadline : nil, status, notifOffsets)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(
                        selectedType == "カスタム" &&
                        customType.trimmingCharacters(in: .whitespaces).isEmpty
                    )
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
    let test = AptitudeTest(context: ctx)
    test.id     = UUID()
    test.type   = "SPI(WEB)"
    test.status = "未受験"
    return AptitudeTestEditView(test: test) { type, custom, deadline, status, offsets in
        print("type: \(type), status: \(status)")
    }
}
#endif
