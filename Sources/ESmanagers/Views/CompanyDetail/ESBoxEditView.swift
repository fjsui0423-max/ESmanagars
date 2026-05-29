import SwiftUI

/// 既存の ES BOX のタイトル・締切日を編集するシート
struct ESBoxEditView: View {
    @Environment(\.dismiss) private var dismiss

    /// 書き換え後の (title, deadline, notifOffsets) を呼び出し元に渡す
    let onSave: (String, Date?, Set<DeadlineOffset>) -> Void

    @State private var title:        String
    @State private var deadline:     Date
    @State private var hasDeadline:  Bool
    @State private var notifOffsets: Set<DeadlineOffset>

    init(esBox: ESBox, onSave: @escaping (String, Date?, Set<DeadlineOffset>) -> Void) {
        self.onSave = onSave
        _title       = State(initialValue: esBox.title      ?? "")
        _hasDeadline = State(initialValue: esBox.deadlineAt != nil)
        _deadline    = State(initialValue: esBox.deadlineAt ?? Date())
        let saved: Set<DeadlineOffset>
        if let id = esBox.id?.uuidString {
            saved = NotificationManager.shared.savedDeadlineOffsets(for: id)
        } else {
            saved = [.oneDay]
        }
        _notifOffsets = State(initialValue: saved)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("ES BOX 名") {
                    TextField("例：本選考ES", text: $title)
                }

                Section {
                    Toggle("締切日を設定する", isOn: $hasDeadline.animation())
                    if hasDeadline {
                        DatePicker(
                            "締切日",
                            selection: $deadline,
                            displayedComponents: .date
                        )
                    }
                } footer: {
                    if hasDeadline {
                        Text("設定した締切日はカレンダー画面にも表示されます。")
                            .font(.caption)
                    }
                }

                if hasDeadline {
                    DeadlineNotificationSection(selectedOffsets: $notifOffsets)
                }
            }
            .navigationTitle("ES BOX を編集")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: cancelPlacement) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: savePlacement) {
                    Button("保存") {
                        onSave(title, hasDeadline ? deadline : nil, notifOffsets)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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
    let box = ESBox(context: ctx)
    box.id    = UUID()
    box.title = "本選考ES"
    return ESBoxEditView(esBox: box) { title, deadline, offsets in
        print("保存: \(title), \(String(describing: deadline)), offsets: \(offsets)")
    }
}
#endif
