import CoreData

@objc(Template)
public final class Template: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var category: String?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Template> {
        NSFetchRequest<Template>(entityName: "Template")
    }
}
