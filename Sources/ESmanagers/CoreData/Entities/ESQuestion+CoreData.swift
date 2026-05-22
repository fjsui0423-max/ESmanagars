import CoreData

@objc(ESQuestion)
public final class ESQuestion: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var questionText: String?
    @NSManaged public var maxLength: Int16
    @NSManaged public var currentAnswer: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var esBox: ESBox?
    @NSManaged public var versions: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ESQuestion> {
        NSFetchRequest<ESQuestion>(entityName: "ESQuestion")
    }

    var versionsArray: [ESVersion] {
        (versions?.allObjects as? [ESVersion] ?? [])
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }
}
