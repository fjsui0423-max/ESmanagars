import UserNotifications
import Foundation

// MARK: - Offset types

enum DeadlineOffset: String, CaseIterable {
    case threeDays = "3days"
    case oneDay    = "1day"
    case sameDay   = "sameday"

    var label: String {
        switch self {
        case .threeDays: return "3日前（9時）"
        case .oneDay:    return "1日前（9時）"
        case .sameDay:   return "当日（9時）"
        }
    }

    var daysBefore: Int {
        switch self {
        case .threeDays: return 3
        case .oneDay:    return 1
        case .sameDay:   return 0
        }
    }
}

enum InterviewOffset: String, CaseIterable {
    case oneDay     = "1day"
    case threeHours = "3hours"
    case oneHour    = "1hour"
    case thirtyMins = "30min"

    var label: String {
        switch self {
        case .oneDay:     return "1日前"
        case .threeHours: return "3時間前"
        case .oneHour:    return "1時間前"
        case .thirtyMins: return "30分前"
        }
    }

    var secondsBefore: TimeInterval {
        switch self {
        case .oneDay:     return 86_400
        case .threeHours: return 10_800
        case .oneHour:    return 3_600
        case .thirtyMins: return 1_800
        }
    }
}

// MARK: - Manager

final class NotificationManager: @unchecked Sendable {
    static let shared = NotificationManager()

    enum Keys {
        static let isEnabled = "notificationIsEnabled"
    }

    private init() {
        UserDefaults.standard.register(defaults: [Keys.isEnabled: true])
    }

    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Per-entity offset persistence

    func savedDeadlineOffsets(for id: String) -> Set<DeadlineOffset> {
        let raw = UserDefaults.standard.stringArray(forKey: "notif_deadline_\(id)") ?? []
        let offsets = raw.compactMap { DeadlineOffset(rawValue: $0) }
        return offsets.isEmpty ? [.oneDay] : Set(offsets)
    }

    func saveDeadlineOffsets(_ offsets: Set<DeadlineOffset>, for id: String) {
        UserDefaults.standard.set(offsets.map(\.rawValue), forKey: "notif_deadline_\(id)")
    }

    func savedInterviewOffsets(for id: String) -> Set<InterviewOffset> {
        let raw = UserDefaults.standard.stringArray(forKey: "notif_interview_\(id)") ?? []
        let offsets = raw.compactMap { InterviewOffset(rawValue: $0) }
        return offsets.isEmpty ? [.oneDay, .oneHour] : Set(offsets)
    }

    func saveInterviewOffsets(_ offsets: Set<InterviewOffset>, for id: String) {
        UserDefaults.standard.set(offsets.map(\.rawValue), forKey: "notif_interview_\(id)")
    }

    // MARK: - Schedule deadline reminders (ESBox / AptitudeTest)

    func scheduleDeadlineReminders(
        id: String,
        title: String,
        companyName: String,
        deadlineAt: Date,
        offsets: Set<DeadlineOffset>
    ) {
        cancelDeadlineReminders(id: id)
        guard UserDefaults.standard.bool(forKey: Keys.isEnabled) else { return }
        saveDeadlineOffsets(offsets, for: id)

        let now = Date()
        let cal = Calendar.current
        for offset in offsets {
            guard let fireDate = deadlineFireDate(for: deadlineAt, daysBefore: offset.daysBefore, cal: cal) else { continue }
            let dayText = offset.daysBefore == 0 ? "本日" : "\(offset.daysBefore)日後"
            schedule(
                id:       "\(id)-dl-\(offset.rawValue)",
                title:    "締切リマインド：\(title)",
                body:     "【\(companyName)】の締切は\(dayText)です",
                fireDate: fireDate,
                after:    now
            )
        }
    }

    func cancelDeadlineReminders(id: String) {
        let ids = DeadlineOffset.allCases.map { "\(id)-dl-\($0.rawValue)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Schedule interview reminders

    func scheduleInterviewReminders(for interview: Interview, offsets: Set<InterviewOffset>) {
        guard let id      = interview.id?.uuidString,
              let startAt = interview.startAt,
              let stage   = interview.stage else { return }

        let companyName = interview.selection?.company?.name ?? "企業名不明"
        cancelReminders(for: interview)
        guard UserDefaults.standard.bool(forKey: Keys.isEnabled) else { return }
        saveInterviewOffsets(offsets, for: id)

        let now = Date()
        for offset in offsets {
            let fireDate = startAt.addingTimeInterval(-offset.secondsBefore)
            schedule(
                id:       "\(id)-int-\(offset.rawValue)",
                title:    interviewNotifTitle(for: offset),
                body:     "【\(companyName)】\(stage)が\(offset.label)から始まります（\(timeString(startAt))）",
                fireDate: fireDate,
                after:    now
            )
        }
    }

    // MARK: - Cancel interview reminders

    func cancelReminders(for interview: Interview) {
        guard let id = interview.id?.uuidString else { return }
        let newIds    = InterviewOffset.allCases.map { "\(id)-int-\($0.rawValue)" }
        let legacyIds = ["\(id)-days", "\(id)-hours", "\(id)-24h", "\(id)-1h"]
        center.removePendingNotificationRequests(withIdentifiers: newIds + legacyIds)
    }

    // MARK: - Reschedule all future interviews

    func rescheduleAllFutureInterviews(interviews: [Interview]) {
        interviews.forEach { cancelReminders(for: $0) }
        let now = Date()
        interviews
            .filter { ($0.startAt ?? .distantPast) > now && $0.status == "予定" }
            .forEach { interview in
                guard let id = interview.id?.uuidString else { return }
                let offsets = savedInterviewOffsets(for: id)
                scheduleInterviewReminders(for: interview, offsets: offsets)
            }
    }

    // MARK: - Private helpers

    private func deadlineFireDate(for deadline: Date, daysBefore: Int, cal: Calendar) -> Date? {
        let deadlineDay = cal.startOfDay(for: deadline)
        guard let fireDay = cal.date(byAdding: .day, value: -daysBefore, to: deadlineDay) else { return nil }
        return cal.date(bySettingHour: 9, minute: 0, second: 0, of: fireDay)
    }

    private func interviewNotifTitle(for offset: InterviewOffset) -> String {
        switch offset {
        case .oneDay:     return "明日の面接リマインド"
        case .threeHours: return "面接まで3時間"
        case .oneHour:    return "面接まで1時間"
        case .thirtyMins: return "面接まで30分"
        }
    }

    private func schedule(id: String, title: String, body: String, fireDate: Date, after now: Date) {
        guard fireDate > now else { return }
        let content   = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let comps     = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger   = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger), withCompletionHandler: nil)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP"); f.timeStyle = .short
        return f.string(from: date)
    }
}
