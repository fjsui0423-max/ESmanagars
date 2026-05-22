import SwiftUI
import CoreData

struct CompanyEditView: View {
    @Environment(\.dismiss)                private var dismiss
    @Environment(\.managedObjectContext)   private var context

    let company: Company

    @State private var name:        String
    @State private var myPageURL:   String
    @State private var loginID:     String
    @State private var password:    String
    @State private var showPassword = false

    init(company: Company) {
        self.company = company
        _name      = State(initialValue: company.name       ?? "")
        _myPageURL = State(initialValue: company.myPageURL  ?? "")
        _loginID   = State(initialValue: company.loginID    ?? "")
        _password  = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 企業情報
                Section("企業情報") {
                    LabeledContent("企業名") {
                        TextField("例：Apple Japan", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("マイページURL") {
                        TextField("https://...", text: $myPageURL)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    LabeledContent("ログインID") {
                        TextField("メールアドレス等", text: $loginID)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                // MARK: パスワード
                Section {
                    HStack {
                        Group {
                            if showPassword {
                                TextField("変更する場合のみ入力", text: $password)
                            } else {
                                SecureField("変更する場合のみ入力", text: $password)
                            }
                        }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }

                    if let key = company.id?.uuidString,
                       KeychainManager.shared.loadPassword(for: key) != nil {
                        Button(role: .destructive) {
                            KeychainManager.shared.deletePassword(for: key)
                            dismiss()
                        } label: {
                            Label("パスワードを削除", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("パスワード（Keychain保存）")
                } footer: {
                    Label(
                        "パスワードはデバイスのKeychainに保存され、バックアップには含まれません。",
                        systemImage: "lock.shield"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("企業情報を編集")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: cancelPlacement) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: savePlacement) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        company.name      = name.trimmingCharacters(in: .whitespaces)
        company.myPageURL = myPageURL.trimmingCharacters(in: .whitespaces)
        company.loginID   = loginID.trimmingCharacters(in: .whitespaces)

        if let key = company.id?.uuidString {
            let trimmedPW = password.trimmingCharacters(in: .whitespaces)
            if !trimmedPW.isEmpty {
                KeychainManager.shared.savePassword(trimmedPW, for: key)
            }
            // 空の場合は既存パスワードを維持（削除しない）
        }

        try? context.save()
        dismiss()
    }

    // MARK: - Placement helpers

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
    let ctx = PersistenceController.preview.context
    let company = (try? Company.fetchAll(in: ctx))?.first ?? Company(context: ctx)
    return CompanyEditView(company: company)
        .environment(\.managedObjectContext, ctx)
}
#endif
