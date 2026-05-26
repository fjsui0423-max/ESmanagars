import SwiftUI

struct InterviewEditView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, Date, String, Set<InterviewOffset>) -> Void

    @State private var stage:        String
    @State private var startAt:      Date
    @State private var mode:         String
    @State private var notifOffsets: Set<InterviewOffset>

    init(interview: Interview, onSave: @escaping (String, Date, String, Set<InterviewOffset>) -> Void) {
        self.onSave = onSave
        _stage   = State(initialValue: interview.stage   ?? "1次面接")
        _startAt = State(initialValue: interview.startAt ?? Date())
        _mode    = State(initialValue: interview.mode    ?? "オンライン")
        let saved: Set<InterviewOffset>
        if let id = interview.id?.uuidString {
            saved = NotificationManager.shared.savedInterviewOffsets(for: id)
        } else {
            saved = [.oneDay, .oneHour]
        }
        _notifOffsets = State(initialValue: saved)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("選考フェーズ") {
                    Picker("フェーズ", selection: $stage) {
                        ForEach(InterviewCreateView.stages, id: \.self) { Text($0) }
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
                        ForEach(InterviewCreateView.modes, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }

                InterviewNotificationSection(selectedOffsets: $notifOffsets)
            }
            .navigationTitle("面接を編集")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: cancelPlacement) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: savePlacement) {
                    Button("保存") {
                        onSave(stage, startAt, mode, notifOffsets)
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
