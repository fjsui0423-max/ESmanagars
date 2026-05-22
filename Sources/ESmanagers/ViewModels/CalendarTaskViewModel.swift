import SwiftUI
import CoreData

@MainActor
final class CalendarTaskViewModel: ObservableObject {

    @Published var selectedDate: Date {
        didSet { filterBoxes() }
    }
    @Published var filteredBoxes: [ESBox] = []

    private var allBoxes: [ESBox] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext, initialDate: Date = Date()) {
        self.context = context
        self.selectedDate = initialDate
        fetch()
    }

    // MARK: - Data

    func fetch() {
        let req = ESBox.fetchRequest()
        req.predicate = NSPredicate(format: "deadlineAt != nil")
        req.sortDescriptors = [NSSortDescriptor(keyPath: \ESBox.deadlineAt, ascending: true)]
        allBoxes = (try? context.fetch(req)) ?? []
        filterBoxes()
    }

    private func filterBoxes() {
        let cal = Calendar.current
        filteredBoxes = allBoxes.filter { box in
            guard let d = box.deadlineAt else { return false }
            return cal.isDate(d, inSameDayAs: selectedDate)
        }
    }
}
