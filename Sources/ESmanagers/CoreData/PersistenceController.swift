import CoreData

final class PersistenceController: @unchecked Sendable {

    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let pc = PersistenceController(inMemory: true)
        PreviewData.populate(context: pc.context)
        return pc
    }()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: "ESmanagers",
            managedObjectModel: CoreDataModel.make()
        )
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        var storeError: Error?
        container.loadPersistentStores { desc, error in
            storeError = error
            // スキーマ変更時は SQLite ファイルを削除して再試行（開発環境用）
            if let error, let url = desc.url {
                print("⚠️ Core Data load failed (\(error)). Resetting store...")
                let fm = FileManager.default
                [url, URL(fileURLWithPath: url.path + "-wal"),
                      URL(fileURLWithPath: url.path + "-shm")].forEach { try? fm.removeItem(at: $0) }
            }
        }
        // スキーマリセット後に再ロード
        if storeError != nil {
            container.loadPersistentStores { _, error in
                if let error { fatalError("Core Data store recovery failed: \(error)") }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }
}
