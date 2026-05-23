import CoreData

@objc(Company)
public final class Company: NSManagedObject, Identifiable {
    @NSManaged public var id:         UUID?
    @NSManaged public var name:       String?
    @NSManaged public var myPageURL:  String?
    @NSManaged public var loginID:    String?
    // loginPassword は Keychain 管理（KeychainManager を使用）
    @NSManaged public var industry:   Industry?
    @NSManaged public var selections: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Company> {
        NSFetchRequest<Company>(entityName: "Company")
    }

    var selectionsArray: [Selection] {
        (selections?.allObjects as? [Selection] ?? [])
            .sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
}

// MARK: - CRUD

extension Company {

    @discardableResult
    static func create(
        name: String,
        myPageURL: String = "",
        loginID: String = "",
        industry: Industry? = nil,
        in context: NSManagedObjectContext
    ) -> Company {
        let obj = Company(context: context)
        obj.id        = UUID()
        obj.name      = name
        obj.myPageURL = myPageURL
        obj.loginID   = loginID
        obj.industry  = industry
        return obj
    }

    static func fetchAll(in context: NSManagedObjectContext) throws -> [Company] {
        let req = fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Company.name, ascending: true)]
        return try context.fetch(req)
    }

    static func fetchStandalone(in context: NSManagedObjectContext) throws -> [Company] {
        let req = fetchRequest()
        req.predicate   = NSPredicate(format: "industry == nil")
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Company.name, ascending: true)]
        return try context.fetch(req)
    }

    func update(name: String? = nil, myPageURL: String? = nil, loginID: String? = nil, industry: Industry? = nil) {
        if let name      { self.name      = name }
        if let myPageURL { self.myPageURL = myPageURL }
        if let loginID   { self.loginID   = loginID }
        if let industry  { self.industry  = industry }
    }
}
