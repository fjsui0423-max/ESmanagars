import UserNotifications
import Foundation

final class NotificationManager: @unchecked Sendable {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Schedule

    func scheduleReminders(for interview: Interview) {
        guard let id          = interview.id?.uuidString,
              let startAt     = interview.startAt,
              let stage       = interview.stage,
              let companyName = interview.company?.name else { return }

        cancelReminders(for: interview)

        let now = Date()

        schedule(
            id:       "\(id)-24h",
            title:    "明日の面接リマインド",
            body:     "【\(companyName)】\(stage)が明日 \(timeString(startAt)) から始まります",
            fireDate: startAt.addingTimeInterval(-86_400),
            after:    now
        )
        schedule(
            id:       "\(id)-1h",
            title:    "面接まで1時間",
            body:     "【\(companyName)】\(stage)が1時間後から始まります",
            fireDate: startAt.addingTimeInterval(-3_600),
            after:    now
        )
    }

    // MARK: - Cancel

    func cancelReminders(for interview: Interview) {
        guard let id = interview.id?.uuidString else { return }
        center.removePendingNotificationRequests(
            withIdentifiers: ["\(id)-24h", "\(id)-1h"]
        )
    }

    // MARK: - Private

    private func schedule(id: String, title: String, body: String, fireDate: Date, after now: Date) {
        guard fireDate > now else { return }
        let content       = UNMutableNotificationContent()
        content.title     = title
        content.body      = body
        content.sound     = .default
        let comps         = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    private func timeString(_ date: Date) -> String {
        let f       = DateFormatter()
        f.locale    = Locale(identifier: "ja_JP")
        f.timeStyle = .short
        return f.string(from: date)
    }
}
