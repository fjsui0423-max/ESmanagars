import UserNotifications
import Foundation

final class NotificationManager: @unchecked Sendable {
    static let shared = NotificationManager()

    // MARK: - UserDefaults keys

    enum Keys {
        static let isEnabled    = "notificationIsEnabled"
        static let daysBefore   = "notificationDaysBefore"
        static let hoursBefore  = "notificationHoursBefore"
    }

    private init() {
        UserDefaults.standard.register(defaults: [
            Keys.isEnabled:   true,
            Keys.daysBefore:  1,
            Keys.hoursBefore: 1
        ])
    }

    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Schedule

    func scheduleReminders(for interview: Interview) {
        guard let id      = interview.id?.uuidString,
              let startAt = interview.startAt,
              let stage   = interview.stage else { return }

        let companyName = interview.selection?.company?.name ?? "企業名不明"
        cancelReminders(for: interview)

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Keys.isEnabled) else { return }

        let daysBefore  = defaults.integer(forKey: Keys.daysBefore)
        let hoursBefore = defaults.integer(forKey: Keys.hoursBefore)
        let now         = Date()

        if daysBefore > 0 {
            let fireDate   = startAt.addingTimeInterval(-Double(daysBefore) * 86_400)
            let titleLabel = daysBefore == 1 ? "明日" : "\(daysBefore)日前"
            let bodyLabel  = daysBefore == 1 ? "明日" : "\(daysBefore)日後"
            schedule(
                id:       "\(id)-days",
                title:    "\(titleLabel)の面接リマインド",
                body:     "【\(companyName)】\(stage)が\(bodyLabel) \(timeString(startAt)) から始まります",
                fireDate: fireDate,
                after:    now
            )
        }

        if hoursBefore > 0 {
            let fireDate = startAt.addingTimeInterval(-Double(hoursBefore) * 3_600)
            let hourText = "\(hoursBefore)時間"
            schedule(
                id:       "\(id)-hours",
                title:    "面接まで\(hourText)",
                body:     "【\(companyName)】\(stage)が\(hourText)後から始まります",
                fireDate: fireDate,
                after:    now
            )
        }
    }

    // MARK: - Cancel

    func cancelReminders(for interview: Interview) {
        guard let id = interview.id?.uuidString else { return }
        center.removePendingNotificationRequests(
            withIdentifiers: ["\(id)-days", "\(id)-hours", "\(id)-24h", "\(id)-1h"]
        )
    }

    // MARK: - Reschedule all future interviews

    func rescheduleAllFutureInterviews(interviews: [Interview]) {
        interviews.forEach { cancelReminders(for: $0) }
        let now = Date()
        interviews
            .filter { ($0.startAt ?? .distantPast) > now && $0.status == "予定" }
            .forEach { scheduleReminders(for: $0) }
    }

    // MARK: - Private

    private func schedule(id: String, title: String, body: String, fireDate: Date, after now: Date) {
        guard fireDate > now else { return }
        let content   = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let comps     = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger), withCompletionHandler: nil)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP"); f.timeStyle = .short
        return f.string(from: date)
    }
}
