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

    var selectionsArray: [Selection] {
        company.selectionsArray
    }

    var hasPassword: Bool {
        keychain.loadPassword(for: companyKey) != nil
    }

    var passwordDisplayText: String {
        if isPasswordVisible, let pw = revealedPassword { return pw }
        return hasPassword ? "••••••••" : "未設定"
    }

    var canTogglePassword: Bool { hasPassword }

    // MARK: - Refresh

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

    // MARK: - Selection

    func addSelection(category: String, title: String, in context: NSManagedObjectContext) {
        let sel = Selection(context: context)
        sel.id       = UUID()
        sel.category = category
        sel.title    = title
        sel.status   = "進行中"
        sel.company  = company
        try? context.save()
        objectWillChange.send()
    }

    func deleteSelection(_ selection: Selection, in context: NSManagedObjectContext) {
        selection.interviewsArray.forEach { NotificationManager.shared.cancelReminders(for: $0) }
        context.delete(selection)
        try? context.save()
        objectWillChange.send()
    }

    func updateSelectionStatus(_ selection: Selection, status: String, in context: NSManagedObjectContext) {
        selection.status = status
        try? context.save()
        objectWillChange.send()
    }

    // MARK: - ESBox

    func addESBox(
        to selection: Selection,
        title: String,
        deadline: Date?,
        notifOffsets: Set<DeadlineOffset>,
        in context: NSManagedObjectContext
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let box = ESBox(context: context)
        let id = UUID()
        box.id         = id
        box.title      = trimmed
        box.status     = "未着手"
        box.deadlineAt = deadline
        box.selection  = selection
        try? context.save()

        if let deadlineAt = deadline {
            let companyName = selection.company?.name ?? "企業名不明"
            NotificationManager.shared.scheduleDeadlineReminders(
                id: id.uuidString, title: trimmed,
                companyName: companyName, deadlineAt: deadlineAt, offsets: notifOffsets
            )
        }
        objectWillChange.send()
    }

    // MARK: - AptitudeTest

    func addAptitudeTest(
        to selection: Selection,
        type: String, customType: String?,
        deadline: Date?, status: String,
        notifOffsets: Set<DeadlineOffset>,
        in context: NSManagedObjectContext
    ) {
        let test = AptitudeTest(context: context)
        let id = UUID()
        test.id         = id
        test.type       = type
        test.customType = customType
        test.deadlineAt = deadline
        test.status     = status
        test.selection  = selection
        try? context.save()

        if let deadlineAt = deadline {
            let companyName = selection.company?.name ?? "企業名不明"
            let displayType = customType.nilIfEmpty ?? type
            NotificationManager.shared.scheduleDeadlineReminders(
                id: id.uuidString, title: displayType,
                companyName: companyName, deadlineAt: deadlineAt, offsets: notifOffsets
            )
        }
        objectWillChange.send()
    }

    func updateAptitudeTestStatus(_ test: AptitudeTest, status: String, in context: NSManagedObjectContext) {
        test.status = status
        try? context.save()
        objectWillChange.send()
    }

    func deleteAptitudeTest(_ test: AptitudeTest, in context: NSManagedObjectContext) {
        if let id = test.id?.uuidString {
            NotificationManager.shared.cancelDeadlineReminders(id: id)
        }
        context.delete(test)
        try? context.save()
        objectWillChange.send()
    }

    // MARK: - Interview

    func addInterview(
        to selection: Selection,
        stage: String, startAt: Date, mode: String,
        notifOffsets: Set<InterviewOffset>,
        in context: NSManagedObjectContext
    ) {
        let interview = Interview(context: context)
        interview.id        = UUID()
        interview.stage     = stage
        interview.startAt   = startAt
        interview.mode      = mode
        interview.status    = "予定"
        interview.selection = selection
        try? context.save()
        NotificationManager.shared.scheduleInterviewReminders(for: interview, offsets: notifOffsets)
        objectWillChange.send()
    }

    func deleteInterview(_ interview: Interview, in context: NSManagedObjectContext) {
        NotificationManager.shared.cancelReminders(for: interview)
        context.delete(interview)
        try? context.save()
        objectWillChange.send()
    }

    func updateInterview(
        _ interview: Interview,
        stage: String, startAt: Date, mode: String,
        notifOffsets: Set<InterviewOffset>,
        in context: NSManagedObjectContext
    ) {
        interview.stage   = stage
        interview.startAt = startAt
        interview.mode    = mode
        try? context.save()
        NotificationManager.shared.scheduleInterviewReminders(for: interview, offsets: notifOffsets)
        objectWillChange.send()
    }

    func updateInterviewStatus(_ interview: Interview, status: String, in context: NSManagedObjectContext) {
        interview.status = status
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
