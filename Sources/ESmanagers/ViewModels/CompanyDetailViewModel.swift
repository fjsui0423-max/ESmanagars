import SwiftUI
import CoreData

#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class CompanyDetailViewModel: ObservableObject {

    let company: Company

    // MARK: - Published state

    @Published var isPasswordVisible = false
    @Published var revealedPassword: String? = nil
    @Published var isAuthenticating  = false
    @Published var showToast         = false
    @Published var toastMessage      = ""

    // MARK: - Dependencies

    private let keychain  = KeychainManager.shared
    private let biometric = BiometricAuthManager.shared
    private var toastTask: Task<Void, Never>?

    private var companyKey: String { company.id?.uuidString ?? "unknown" }

    // MARK: - Init

    init(company: Company) {
        self.company = company
    }

    // MARK: - Computed

    var myPageURL: URL? {
        company.myPageURL.nilIfEmpty.flatMap { URL(string: $0) }
    }

    var esBoxesArray: [ESBox] {
        (company.esBoxes?.allObjects as? [ESBox] ?? [])
            .sorted { ($0.deadlineAt ?? .distantFuture) < ($1.deadlineAt ?? .distantFuture) }
    }

    var interviewsArray: [Interview] {
        (company.interviews?.allObjects as? [Interview] ?? [])
            .sorted { ($0.startAt ?? .distantFuture) < ($1.startAt ?? .distantFuture) }
    }

    var hasPassword: Bool {
        keychain.loadPassword(for: companyKey) != nil
    }

    var passwordDisplayText: String {
        if isPasswordVisible, let pw = revealedPassword { return pw }
        return hasPassword ? "••••••••" : "未設定"
    }

    var canTogglePassword: Bool { hasPassword }

    // MARK: - Refresh（編集シート閉じた後に呼ぶ）

    func refreshCompanyData() {
        isPasswordVisible = false
        revealedPassword  = nil
        objectWillChange.send()
    }

    // MARK: - ID actions

    func copyLoginID() {
        #if canImport(UIKit)
        UIPasteboard.general.string = company.loginID ?? ""
        #endif
        triggerToast("ログインIDをコピーしました")
    }

    func openURLAndCopyID(open: OpenURLAction) {
        if company.loginID.nilIfEmpty != nil {
            #if canImport(UIKit)
            UIPasteboard.general.string = company.loginID ?? ""
            #endif
            triggerToast("IDをコピーしました")
        }
        if let url = myPageURL { open(url) }
    }

    // MARK: - Password actions

    func togglePasswordVisibility() async {
        if isPasswordVisible {
            withAnimation(.spring(duration: 0.2)) {
                isPasswordVisible = false
                revealedPassword  = nil
            }
            return
        }
        guard hasPassword else { return }

        isAuthenticating = true
        let ok = await biometric.authenticate(reason: "パスワードを表示するために認証が必要です")
        isAuthenticating = false
        guard ok else { return }

        revealedPassword = keychain.loadPassword(for: companyKey)
        withAnimation(.spring(duration: 0.2)) { isPasswordVisible = true }
    }

    func copyPassword() async {
        guard hasPassword else { return }

        isAuthenticating = true
        let ok = await biometric.authenticate(reason: "パスワードをクリップボードにコピーします")
        isAuthenticating = false
        guard ok, let pw = keychain.loadPassword(for: companyKey) else { return }

        #if canImport(UIKit)
        UIPasteboard.general.string = pw
        #endif
        triggerToast("パスワードをコピーしました")
    }

    // MARK: - Interview

    func addInterview(stage: String, startAt: Date, mode: String, in context: NSManagedObjectContext) {
        let interview = Interview.create(stage: stage, startAt: startAt, mode: mode, company: company, in: context)
        try? context.save()
        NotificationManager.shared.scheduleReminders(for: interview)
        objectWillChange.send()
    }

    func deleteInterview(_ interview: Interview, in context: NSManagedObjectContext) {
        NotificationManager.shared.cancelReminders(for: interview)
        context.delete(interview)
        try? context.save()
        objectWillChange.send()
    }

    func updateInterviewStatus(_ interview: Interview, status: String, in context: NSManagedObjectContext) {
        interview.status = status
        try? context.save()
        objectWillChange.send()
    }

    // MARK: - ESBox

    func addESBox(title: String, deadline: Date?, in context: NSManagedObjectContext) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let box = ESBox(context: context)
        box.id        = UUID()
        box.title     = trimmed
        box.status    = "未着手"
        box.deadlineAt = deadline
        box.company   = company
        try? context.save()
        objectWillChange.send()
    }

    // MARK: - Toast

    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(duration: 0.3)) { showToast = true }
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                withAnimation(.spring(duration: 0.3)) { showToast = false }
            }
        }
    }
}
