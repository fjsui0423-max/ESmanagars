import CoreData

@objc(Selection)
public final class Selection: NSManagedObject, Identifiable {
    @NSManaged public var id:           UUID?
    @NSManaged public var category:     String?   // "インターン" / "本選考"
    @NSManaged public var title:        String?
    @NSManaged public var status:       String?   // "進行中" / "インターン参加" / "内定" / "落選" / "辞退"
    @NSManaged public var company:      Company?
    @NSManaged public var esBoxes:      NSSet?
    @NSManaged public var aptitudeTests: NSSet?
    @NSManaged public var interviews:   NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Selection> {
        NSFetchRequest<Selection>(entityName: "Selection")
    }

    var esBoxesArray: [ESBox] {
        (esBoxes?.allObjects as? [ESBox] ?? [])
            .sorted { ($0.deadlineAt ?? .distantFuture) < ($1.deadlineAt ?? .distantFuture) }
    }

    var aptitudeTestsArray: [AptitudeTest] {
        (aptitudeTests?.allObjects as? [AptitudeTest] ?? [])
            .sorted { ($0.deadlineAt ?? .distantFuture) < ($1.deadlineAt ?? .distantFuture) }
    }

    var interviewsArray: [Interview] {
        (interviews?.allObjects as? [Interview] ?? [])
            .sorted { ($0.startAt ?? .distantFuture) < ($1.startAt ?? .distantFuture) }
    }
}

// MARK: - Constants & CRUD

extension Selection {
    static let categories: [String] = ["インターン", "本選考"]
    static let statuses:   [String] = ["進行中", "インターン参加", "内定", "落選", "辞退"]

    @discardableResult
    static func create(
        category: String,
        title: String,
        company: Company,
        in context: NSManagedObjectContext
    ) -> Selection {
        let s = Selection(context: context)
        s.id       = UUID()
        s.category = category
        s.title    = title.trimmingCharacters(in: .whitespaces)
        s.status   = "進行中"
        s.company  = company
        return s
    }
}
