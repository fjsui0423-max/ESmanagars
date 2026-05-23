import SwiftUI
import CoreData

@MainActor
final class CalendarTaskViewModel: ObservableObject {

    @Published var selectedDate: Date {
        didSet { filterItems() }
    }
    @Published var filteredBoxes:      [ESBox]     = []
    @Published var filteredInterviews: [Interview] = []

    private var allBoxes:      [ESBox]     = []
    private var allInterviews: [Interview] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext, initialDate: Date = Date()) {
        self.context = context
        self.selectedDate = initialDate
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

    // MARK: - Private

    private func filterItems() {
        let cal = Calendar.current
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
