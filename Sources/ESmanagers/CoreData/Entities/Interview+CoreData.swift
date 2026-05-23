import CoreData

@objc(Interview)
public final class Interview: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var stage: String?
    @NSManaged public var startAt: Date?
    @NSManaged public var mode: String?
    @NSManaged public var status: String?
    @NSManaged public var company: Company?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Interview> {
        NSFetchRequest<Interview>(entityName: "Interview")
    }
}

extension Interview {

    @discardableResult
    static func create(
        stage: String,
        startAt: Date,
        mode: String,
        company: Company,
        in context: NSManagedObjectContext
    ) -> Interview {
        let i = Interview(context: context)
        i.id      = UUID()
        i.stage   = stage
        i.startAt = startAt
        i.mode    = mode
        i.status  = "予定"
        i.company = company
        return i
    }
}
