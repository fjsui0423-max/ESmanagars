import CoreData

enum CoreDataModel {
    static func make() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: - Entity builders

        func makeAttr(_ name: String, _ type: NSAttributeType, optional: Bool = true) -> NSAttributeDescription {
            let d = NSAttributeDescription()
            d.name = name
            d.attributeType = type
            d.isOptional = optional
            return d
        }

        func makeRelationship(
            name: String, destination: NSEntityDescription,
            toMany: Bool, deleteRule: NSDeleteRule = .nullifyDeleteRule,
            ordered: Bool = false
        ) -> NSRelationshipDescription {
            let r = NSRelationshipDescription()
            r.name = name
            r.destinationEntity = destination
            r.minCount = 0
            r.maxCount = toMany ? 0 : 1
            r.isOrdered = ordered
            r.deleteRule = deleteRule
            return r
        }

        // MARK: - Entities

        let industry = NSEntityDescription()
        industry.name = "Industry"
        industry.managedObjectClassName = "Industry"
        industry.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("name", .stringAttributeType),
            makeAttr("sortOrder", .integer16AttributeType, optional: false)
        ]

        let company = NSEntityDescription()
        company.name = "Company"
        company.managedObjectClassName = "Company"
        company.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("name", .stringAttributeType),
            makeAttr("myPageURL", .stringAttributeType),
            makeAttr("loginID", .stringAttributeType)
            // loginPassword は Keychain に移行済み
        ]

        let esBox = NSEntityDescription()
        esBox.name = "ESBox"
        esBox.managedObjectClassName = "ESBox"
        esBox.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("title", .stringAttributeType),
            makeAttr("deadlineAt", .dateAttributeType),
            makeAttr("status", .stringAttributeType)
        ]

        let esQuestion = NSEntityDescription()
        esQuestion.name = "ESQuestion"
        esQuestion.managedObjectClassName = "ESQuestion"
        esQuestion.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("questionText", .stringAttributeType),
            makeAttr("maxLength", .integer16AttributeType, optional: false),
            makeAttr("currentAnswer", .stringAttributeType),
            makeAttr("sortOrder", .integer16AttributeType, optional: false)
        ]

        let esVersion = NSEntityDescription()
        esVersion.name = "ESVersion"
        esVersion.managedObjectClassName = "ESVersion"
        esVersion.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("savedAnswer", .stringAttributeType),
            makeAttr("createdAt", .dateAttributeType)
        ]

        let template = NSEntityDescription()
        template.name = "Template"
        template.managedObjectClassName = "Template"
        template.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("title", .stringAttributeType),
            makeAttr("content", .stringAttributeType),
            makeAttr("category", .stringAttributeType)
        ]

        let interview = NSEntityDescription()
        interview.name = "Interview"
        interview.managedObjectClassName = "Interview"
        interview.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("stage", .stringAttributeType),
            makeAttr("startAt", .dateAttributeType),
            makeAttr("mode", .stringAttributeType),
            makeAttr("status", .stringAttributeType)
        ]

        // MARK: - Relationships

        // Industry <->> Company
        let industryToCompanies = makeRelationship(name: "companies", destination: company, toMany: true, deleteRule: .cascadeDeleteRule)
        let companyToIndustry   = makeRelationship(name: "industry",  destination: industry, toMany: false)
        industryToCompanies.inverseRelationship = companyToIndustry
        companyToIndustry.inverseRelationship   = industryToCompanies
        industry.properties += [industryToCompanies]
        company.properties  += [companyToIndustry]

        // Company <->> ESBox
        let companyToESBoxes = makeRelationship(name: "esBoxes", destination: esBox, toMany: true, deleteRule: .cascadeDeleteRule)
        let esBoxToCompany   = makeRelationship(name: "company", destination: company, toMany: false)
        companyToESBoxes.inverseRelationship = esBoxToCompany
        esBoxToCompany.inverseRelationship   = companyToESBoxes
        company.properties += [companyToESBoxes]
        esBox.properties   += [esBoxToCompany]

        // ESBox <->> ESQuestion (ordered)
        let esBoxToQuestions  = makeRelationship(name: "esQuestions", destination: esQuestion, toMany: true, deleteRule: .cascadeDeleteRule, ordered: true)
        let esQuestionToBox   = makeRelationship(name: "esBox",       destination: esBox, toMany: false)
        esBoxToQuestions.inverseRelationship = esQuestionToBox
        esQuestionToBox.inverseRelationship  = esBoxToQuestions
        esBox.properties       += [esBoxToQuestions]
        esQuestion.properties  += [esQuestionToBox]

        // ESQuestion <->> ESVersion
        let questionToVersions = makeRelationship(name: "versions",    destination: esVersion,  toMany: true,  deleteRule: .cascadeDeleteRule)
        let versionToQuestion  = makeRelationship(name: "esQuestion",  destination: esQuestion, toMany: false)
        questionToVersions.inverseRelationship = versionToQuestion
        versionToQuestion.inverseRelationship  = questionToVersions
        esQuestion.properties += [questionToVersions]
        esVersion.properties  += [versionToQuestion]

        // Company <->> Interview
        let companyToInterviews = makeRelationship(name: "interviews", destination: interview, toMany: true, deleteRule: .cascadeDeleteRule)
        let interviewToCompany  = makeRelationship(name: "company",    destination: company,   toMany: false)
        companyToInterviews.inverseRelationship = interviewToCompany
        interviewToCompany.inverseRelationship  = companyToInterviews
        company.properties   += [companyToInterviews]
        interview.properties += [interviewToCompany]

        model.entities = [industry, company, esBox, esQuestion, esVersion, template, interview]
        return model
    }
}
