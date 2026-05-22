import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CoreData

// MARK: - Root backup envelope

struct BackupData: Codable {
    let exportedAt: Date
    let industries: [IndustryDTO]
    let standaloneCompanies: [CompanyDTO]
    let templates: [TemplateDTO]
}

// MARK: - DTOs (パスワードは含めない)

struct IndustryDTO: Codable {
    let id: UUID
    let name: String
    let sortOrder: Int16
    let companies: [CompanyDTO]
}

struct CompanyDTO: Codable {
    let id: UUID
    let name: String
    let myPageURL: String?
    let loginID: String?
    let esBoxes: [ESBoxDTO]
}

struct ESBoxDTO: Codable {
    let id: UUID
    let title: String?
    let deadlineAt: Date?
    let status: String?
    let questions: [ESQuestionDTO]
}

struct ESQuestionDTO: Codable {
    let id: UUID
    let questionText: String?
    let maxLength: Int16
    let currentAnswer: String?
    let sortOrder: Int16
    let versions: [ESVersionDTO]
}

struct ESVersionDTO: Codable {
    let id: UUID
    let savedAnswer: String?
    let createdAt: Date?
}

struct TemplateDTO: Codable {
    let id: UUID
    let title: String?
    let content: String?
    let category: String?
}

// MARK: - NSManagedObject → DTO conversions

extension Industry {
    var dto: IndustryDTO {
        IndustryDTO(
            id: id ?? UUID(),
            name: name ?? "",
            sortOrder: sortOrder,
            companies: companiesArray.map(\.dto)
        )
    }
}

extension Company {
    var dto: CompanyDTO {
        let boxes = (esBoxes?.allObjects as? [ESBox] ?? [])
            .sorted { ($0.deadlineAt ?? .distantPast) < ($1.deadlineAt ?? .distantPast) }
        return CompanyDTO(
            id: id ?? UUID(),
            name: name ?? "",
            myPageURL: myPageURL,
            loginID: loginID,
            esBoxes: boxes.map(\.dto)
        )
    }
}

extension ESBox {
    var dto: ESBoxDTO {
        ESBoxDTO(
            id: id ?? UUID(),
            title: title,
            deadlineAt: deadlineAt,
            status: status,
            questions: questionsArray.map(\.dto)
        )
    }
}

extension ESQuestion {
    var dto: ESQuestionDTO {
        ESQuestionDTO(
            id: id ?? UUID(),
            questionText: questionText,
            maxLength: maxLength,
            currentAnswer: currentAnswer,
            sortOrder: sortOrder,
            versions: versionsArray.map(\.dto)
        )
    }
}

extension ESVersion {
    var dto: ESVersionDTO {
        ESVersionDTO(
            id: id ?? UUID(),
            savedAnswer: savedAnswer,
            createdAt: createdAt
        )
    }
}

extension Template {
    var dto: TemplateDTO {
        TemplateDTO(
            id: id ?? UUID(),
            title: title,
            content: content,
            category: category
        )
    }
}

// MARK: - FileDocument wrapper for fileExporter

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
