import CoreData

@objc(Industry)
public final class Industry: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var companies: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Industry> {
        NSFetchRequest<Industry>(entityName: "Industry")
    }

    var companiesArray: [Company] {
        (companies?.allObjects as? [Company] ?? [])
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
}

// MARK: - CRUD

extension Industry {

    @discardableResult
    static func create(
        name: String,
        sortOrder: Int16 = 0,
        in context: NSManagedObjectContext
    ) -> Industry {
        let obj = Industry(context: context)
        obj.id = UUID()
        obj.name = name
        obj.sortOrder = sortOrder
        return obj
    }

    static func fetchAll(in context: NSManagedObjectContext) throws -> [Industry] {
        let req = fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Industry.sortOrder, ascending: true)]
        return try context.fetch(req)
    }

    func update(name: String? = nil, sortOrder: Int16? = nil) {
        if let name { self.name = name }
        if let sortOrder { self.sortOrder = sortOrder }
    }
}
