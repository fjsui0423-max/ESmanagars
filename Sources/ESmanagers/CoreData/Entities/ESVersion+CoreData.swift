import CoreData

@objc(ESVersion)
public final class ESVersion: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var savedAnswer: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var esQuestion: ESQuestion?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ESVersion> {
        NSFetchRequest<ESVersion>(entityName: "ESVersion")
    }
}
