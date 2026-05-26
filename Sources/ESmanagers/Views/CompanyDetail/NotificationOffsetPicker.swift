import SwiftUI

// MARK: - Deadline notification section

struct DeadlineNotificationSection: View {
    @Binding var selectedOffsets: Set<DeadlineOffset>

    var body: some View {
        Section {
            ForEach(DeadlineOffset.allCases, id: \.rawValue) { offset in
                Toggle(offset.label, isOn: Binding(
                    get: { selectedOffsets.contains(offset) },
                    set: { on in
                        if on { selectedOffsets.insert(offset) }
                        else  { selectedOffsets.remove(offset) }
                    }
                ))
            }
        } header: {
            Label("通知タイミング", systemImage: "bell")
        } footer: {
            Text("締切日の9時ごろに通知が届きます。通知を受け取らない場合は全てオフにしてください。")
                .font(.caption)
        }
    }
}

// MARK: - Interview notification section

struct InterviewNotificationSection: View {
    @Binding var selectedOffsets: Set<InterviewOffset>

    var body: some View {
        Section {
            ForEach(InterviewOffset.allCases, id: \.rawValue) { offset in
                Toggle(offset.label, isOn: Binding(
                    get: { selectedOffsets.contains(offset) },
                    set: { on in
                        if on { selectedOffsets.insert(offset) }
                        else  { selectedOffsets.remove(offset) }
                    }
                ))
            }
        } header: {
            Label("通知タイミング", systemImage: "bell")
        } footer: {
            Text("面接開始時刻の前に通知が届きます。通知を受け取らない場合は全てオフにしてください。")
                .font(.caption)
        }
    }
}
