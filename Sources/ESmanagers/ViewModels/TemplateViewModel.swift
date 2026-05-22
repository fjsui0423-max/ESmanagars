import SwiftUI
import CoreData

@MainActor
final class TemplateViewModel: ObservableObject {

    @Published var groupedTemplates: [String: [Template]] = [:]
    @Published var allCategories: [String] = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetch()
    }

    // MARK: - Fetch

    func fetch() {
        let req = Template.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(keyPath: \Template.category, ascending: true),
            NSSortDescriptor(keyPath: \Template.title,    ascending: true)
        ]
        let templates = (try? context.fetch(req)) ?? []

        var grouped: [String: [Template]] = [:]
        for t in templates {
            let key = (t.category ?? "").isEmpty ? "未分類" : t.category!
            grouped[key, default: []].append(t)
        }
        groupedTemplates = grouped
        allCategories = grouped.keys.sorted()
    }

    // MARK: - Create / Update

    func save(template: Template? = nil,
              title: String,
              content: String,
              category: String) {
        let t = template ?? Template(context: context)
        if t.id == nil { t.id = UUID() }
        t.title    = title.trimmingCharacters(in: .whitespaces)
        t.content  = content
        t.category = category.trimmingCharacters(in: .whitespaces)
        try? context.save()
        fetch()
    }

    // MARK: - Delete

    func delete(_ template: Template) {
        context.delete(template)
        try? context.save()
        fetch()
    }

    func delete(category: String, at offsets: IndexSet) {
        guard let templates = groupedTemplates[category] else { return }
        offsets.map { templates[$0] }.forEach { context.delete($0) }
        try? context.save()
        fetch()
    }
}
