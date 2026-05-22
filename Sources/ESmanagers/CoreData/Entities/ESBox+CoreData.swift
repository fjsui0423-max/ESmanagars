import CoreData

@objc(ESBox)
public final class ESBox: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var deadlineAt: Date?
    @NSManaged public var status: String?
    @NSManaged public var company: Company?
    @NSManaged public var esQuestions: NSOrderedSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ESBox> {
        NSFetchRequest<ESBox>(entityName: "ESBox")
    }

    var questionsArray: [ESQuestion] {
        esQuestions?.array as? [ESQuestion] ?? []
    }
}
