import SwiftUI
import CoreData

// MARK: - Error type

enum BackupError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied: return "ファイルへのアクセス権限がありません"
        }
    }
}

// MARK: - ViewModel

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var showAlert    = false
    @Published var alertTitle   = ""
    @Published var alertMessage = ""

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Export

    /// Core DataをDTOに変換してJSONDocumentとして返す。失敗時はアラートを出してnilを返す。
    func exportJSON() -> JSONDocument? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting    = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(buildBackupData())
            return JSONDocument(data: data)
        } catch {
            present(title: "エクスポート失敗", message: error.localizedDescription)
            return nil
        }
    }

    private func buildBackupData() throws -> BackupData {
        let industryReq = Industry.fetchRequest()
        industryReq.sortDescriptors = [NSSortDescriptor(keyPath: \Industry.sortOrder, ascending: true)]
        let industries = try context.fetch(industryReq)

        let companyReq = Company.fetchRequest()
        companyReq.predicate = NSPredicate(format: "industry == nil")
        let standaloneCompanies = try context.fetch(companyReq)

        let templateReq = Template.fetchRequest()
        templateReq.sortDescriptors = [
            NSSortDescriptor(keyPath: \Template.category, ascending: true),
            NSSortDescriptor(keyPath: \Template.title,    ascending: true)
        ]
        let templates = try context.fetch(templateReq)

        return BackupData(
            exportedAt: Date(),
            industries: industries.map(\.dto),
            standaloneCompanies: standaloneCompanies.map(\.dto),
            templates: templates.map(\.dto)
        )
    }

    // MARK: - Import

    /// ファイルURLからJSONを読み込み、既存データを全削除して復元する。
    func importJSON(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw BackupError.accessDenied
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let data   = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(BackupData.self, from: data)

            try deleteAllData()
            try restore(from: backup)

            present(title: "復元完了", message: "データを正常に復元しました。")
        } catch {
            present(title: "インポート失敗", message: error.localizedDescription)
        }
    }

    // MARK: - Private helpers

    /// 依存順（子→親）でフェッチ削除し、@FetchRequest への変更通知を保証する。
    private func deleteAllData() throws {
        let entityNames = ["ESVersion", "ESQuestion", "ESBox", "Company", "Industry", "Template"]
        for name in entityNames {
            let req = NSFetchRequest<NSManagedObject>(entityName: name)
            let objects = try context.fetch(req)
            objects.forEach { context.delete($0) }
        }
        try context.save()
    }

    private func restore(from backup: BackupData) throws {
        for dto in backup.industries {
            let industry = Industry(context: context)
            industry.id        = dto.id
            industry.name      = dto.name
            industry.sortOrder = dto.sortOrder
            for companyDTO in dto.companies {
                makeCompany(from: companyDTO, industry: industry)
            }
        }
        for dto in backup.standaloneCompanies {
            makeCompany(from: dto, industry: nil)
        }
        for dto in backup.templates {
            let t = Template(context: context)
            t.id = dto.id; t.title = dto.title; t.content = dto.content; t.category = dto.category
        }
        try context.save()
    }

    private func makeCompany(from dto: CompanyDTO, industry: Industry?) {
        let company = Company(context: context)
        company.id        = dto.id
        company.name      = dto.name
        company.myPageURL = dto.myPageURL
        company.loginID   = dto.loginID
        company.industry  = industry

        for boxDTO in dto.esBoxes {
            let box = ESBox(context: context)
            box.id         = boxDTO.id
            box.title      = boxDTO.title
            box.deadlineAt = boxDTO.deadlineAt
            box.status     = boxDTO.status
            box.company    = company

            for questionDTO in boxDTO.questions {
                let q = ESQuestion(context: context)
                q.id            = questionDTO.id
                q.questionText  = questionDTO.questionText
                q.maxLength     = questionDTO.maxLength
                q.currentAnswer = questionDTO.currentAnswer
                q.sortOrder     = questionDTO.sortOrder
                q.esBox         = box

                for versionDTO in questionDTO.versions {
                    let v = ESVersion(context: context)
                    v.id          = versionDTO.id
                    v.savedAnswer = versionDTO.savedAnswer
                    v.createdAt   = versionDTO.createdAt
                    v.esQuestion  = q
                }
            }
        }
    }

    // MARK: - Alert

    func presentError(_ message: String) {
        present(title: "エラー", message: message)
    }

    private func present(title: String, message: String) {
        alertTitle   = title
        alertMessage = message
        showAlert    = true
    }
}
