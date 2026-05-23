import SwiftUI

struct ESQuestionCreateView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, Int16) -> Void

    @State private var questionText  = ""
    @State private var maxLengthText = ""
    @FocusState private var isQuestionFocused: Bool

    private var canSave: Bool {
        !questionText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ZStack(alignment: .topLeading) {
                        if questionText.isEmpty {
                            Text("例：学生時代に最も力を入れたことを教えてください。")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $questionText)
                            .focused($isQuestionFocused)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                    }
                } header: {
                    HStack {
                        Text("設問文")
                        Spacer()
                        Text("\(questionText.count) 文字")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Section {
                    TextField("例：400（空欄で制限なし）", text: $maxLengthText)
                        .keyboardType(.numberPad)
                } header: {
                    Text("文字数制限")
                } footer: {
                    Text("空欄または 0 の場合、文字数制限なしとして扱います。")
                        .font(.caption)
                }
            }
            .navigationTitle("設問を追加")
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
                        isQuestionFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
                #endif
            }
        }
    }

    private func saveAndDismiss() {
        let trimmed = questionText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let max = Int16(maxLengthText.trimmingCharacters(in: .whitespaces)) ?? 0
        onSave(trimmed, max)
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
#Preview {
    ESQuestionCreateView { text, max in
        print("saved: \(text), max: \(max)")
    }
}
#endif
