import CoreData

@objc(AptitudeTest)
public final class AptitudeTest: NSManagedObject, Identifiable {
    @NSManaged public var id:         UUID?
    @NSManaged public var type:       String?   // 検査種別
    @NSManaged public var customType: String?   // type == "カスタム" のときに使用
    @NSManaged public var deadlineAt: Date?
    @NSManaged public var status:     String?   // "未受験" / "受験済み" / "合格" / "落選"
    @NSManaged public var selection:  Selection?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AptitudeTest> {
        NSFetchRequest<AptitudeTest>(entityName: "AptitudeTest")
    }

    var displayType: String {
        if type == "カスタム", let custom = customType, !custom.isEmpty { return custom }
        return type ?? "不明"
    }
}

// MARK: - Constants & CRUD

extension AptitudeTest {
    static let types: [String] = [
        "SPI(WEB)", "SPI(テストセンター)",
        "GAB", "CAB",
        "GAB(テストセンター)", "CAB(テストセンター)",
        "TGWEB", "玉手箱", "カスタム"
    ]
    static let statuses: [String] = ["未受験", "受験済み", "合格", "落選"]

    @discardableResult
    static func create(
        type: String,
        customType: String = "",
        deadlineAt: Date?,
        selection: Selection,
        in context: NSManagedObjectContext
    ) -> AptitudeTest {
        let t = AptitudeTest(context: context)
        t.id         = UUID()
        t.type       = type
        t.customType = customType
        t.deadlineAt = deadlineAt
        t.status     = "未受験"
        t.selection  = selection
        return t
    }
}
