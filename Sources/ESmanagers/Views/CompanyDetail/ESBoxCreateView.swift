import SwiftUI

struct ESBoxCreateView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, Date?, Set<DeadlineOffset>) -> Void

    @State private var title        = ""
    @State private var deadline     = Date()
    @State private var hasDeadline  = false
    @State private var notifOffsets: Set<DeadlineOffset> = [.oneDay]

    var body: some View {
        NavigationStack {
            Form {
                Section("選考フェーズ") {
                    TextField("例：サマーインターン", text: $title)
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
            .navigationTitle("新規ES BOX作成")
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

// MARK: - Preview

#if os(iOS)
#Preview {
    ESBoxCreateView { title, deadline, offsets in
        print("保存: \(title), \(String(describing: deadline)), offsets: \(offsets)")
    }
}
#endif
