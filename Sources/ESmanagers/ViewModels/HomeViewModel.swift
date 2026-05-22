import CoreData
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Industry CRUD

    func addIndustry(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let count = (try? Industry.fetchAll(in: context).count) ?? 0
        Industry.create(name: trimmed, sortOrder: Int16(count), in: context)
        saveContext()
    }

    func deleteIndustry(_ industry: Industry) {
        context.delete(industry)
        saveContext()
    }

    // MARK: - Company CRUD

    func addCompany(name: String, industry: Industry? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Company.create(name: trimmed, industry: industry, in: context)
        saveContext()
    }

    func deleteCompany(_ company: Company) {
        context.delete(company)
        saveContext()
    }

    // MARK: - Drag & Drop: フォルダにグループ化

    /// sourceID の企業と target の企業を、新規 Industry（フォルダ）に紐付ける。
    func createFolderAndGroup(name: String, sourceID: UUID, target: Company) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // sourceID から企業を検索
        let req = Company.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", sourceID as NSUUID)
        guard let source = (try? context.fetch(req))?.first,
              source.objectID != target.objectID else { return }

        let count    = (try? Industry.fetchAll(in: context).count) ?? 0
        let industry = Industry.create(name: trimmed, sortOrder: Int16(count), in: context)
        source.industry = industry
        target.industry = industry
        saveContext()
    }

    // MARK: - Private

    private func saveContext() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}
