import SwiftUI
import CoreData

@MainActor
final class CalendarTaskViewModel: ObservableObject {

    @Published var selectedDate: Date {
        didSet { filterItems() }
    }
    @Published var currentMonth: Date
    @Published var filteredBoxes:      [ESBox]     = []
    @Published var filteredInterviews: [Interview] = []

    private var allBoxes:      [ESBox]     = []
    private var allInterviews: [Interview] = []
    private let context: NSManagedObjectContext
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "ja_JP")
        c.firstWeekday = 1 // Sunday
        return c
    }()

    init(context: NSManagedObjectContext, initialDate: Date = Date()) {
        self.context = context
        self.selectedDate = initialDate
        self.currentMonth = initialDate
        fetch()
    }

    // MARK: - Data

    func fetch() {
        let boxReq = ESBox.fetchRequest()
        boxReq.predicate = NSPredicate(format: "deadlineAt != nil")
        boxReq.sortDescriptors = [NSSortDescriptor(keyPath: \ESBox.deadlineAt, ascending: true)]
        allBoxes = (try? context.fetch(boxReq)) ?? []

        let intReq = Interview.fetchRequest()
        intReq.predicate = NSPredicate(format: "startAt != nil")
        intReq.sortDescriptors = [NSSortDescriptor(keyPath: \Interview.startAt, ascending: true)]
        allInterviews = (try? context.fetch(intReq)) ?? []

        filterItems()
    }

    var isEmpty: Bool { filteredBoxes.isEmpty && filteredInterviews.isEmpty }

    // MARK: - Calendar grid

    var calendarDates: [Date] {
        guard let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) else { return [] }
        let firstWeekday = cal.component(.weekday, from: firstOfMonth) // 1=Sun…7=Sat
        let startOffset = firstWeekday - cal.firstWeekday
        guard let gridStart = cal.date(byAdding: .day, value: -startOffset, to: firstOfMonth) else { return [] }
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: gridStart) }
    }

    func moveToPreviousMonth() {
        if let d = cal.date(byAdding: .month, value: -1, to: currentMonth) { currentMonth = d }
    }

    func moveToNextMonth() {
        if let d = cal.date(byAdding: .month, value: 1, to: currentMonth) { currentMonth = d }
    }

    func isCurrentMonth(_ date: Date) -> Bool {
        cal.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    func isToday(_ date: Date) -> Bool { cal.isDateInToday(date) }

    func isSelected(_ date: Date) -> Bool { cal.isDate(date, inSameDayAs: selectedDate) }

    // MARK: - Per-day queries

    func boxes(for date: Date) -> [ESBox] {
        allBoxes.filter { guard let d = $0.deadlineAt else { return false }; return cal.isDate(d, inSameDayAs: date) }
    }

    func interviews(for date: Date) -> [Interview] {
        allInterviews.filter { guard let d = $0.startAt else { return false }; return cal.isDate(d, inSameDayAs: date) }
    }

    // MARK: - Private

    private func filterItems() {
        filteredBoxes = allBoxes.filter { box in
            guard let d = box.deadlineAt else { return false }
            return cal.isDate(d, inSameDayAs: selectedDate)
        }
        filteredInterviews = allInterviews.filter { interview in
            guard let d = interview.startAt else { return false }
            return cal.isDate(d, inSameDayAs: selectedDate)
        }
    }
}
