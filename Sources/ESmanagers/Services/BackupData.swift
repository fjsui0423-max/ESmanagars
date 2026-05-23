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

// MARK: - DTOs（パスワードは含めない）

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
    let selections: [SelectionDTO]
}

struct SelectionDTO: Codable {
    let id: UUID
    let category: String?
    let title: String?
    let status: String?
    let esBoxes: [ESBoxDTO]
    let aptitudeTests: [AptitudeTestDTO]
    let interviews: [InterviewDTO]
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

struct AptitudeTestDTO: Codable {
    let id: UUID
    let type: String?
    let customType: String?
    let deadlineAt: Date?
    let status: String?
}

struct InterviewDTO: Codable {
    let id: UUID
    let stage: String?
    let startAt: Date?
    let mode: String?
    let status: String?
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
        CompanyDTO(
            id: id ?? UUID(),
            name: name ?? "",
            myPageURL: myPageURL,
            loginID: loginID,
            selections: selectionsArray.map(\.dto)
        )
    }
}

extension Selection {
    var dto: SelectionDTO {
        SelectionDTO(
            id: id ?? UUID(),
            category: category,
            title: title,
            status: status,
            esBoxes: esBoxesArray.map(\.dto),
            aptitudeTests: aptitudeTestsArray.map(\.dto),
            interviews: interviewsArray.map(\.dto)
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

extension AptitudeTest {
    var dto: AptitudeTestDTO {
        AptitudeTestDTO(
            id: id ?? UUID(),
            type: type,
            customType: customType,
            deadlineAt: deadlineAt,
            status: status
        )
    }
}

extension Interview {
    var dto: InterviewDTO {
        InterviewDTO(
            id: id ?? UUID(),
            stage: stage,
            startAt: startAt,
            mode: mode,
            status: status
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

    init(data: Data) { self.data = data }

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
