import CoreData

enum CoreDataModel {
    static func make() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: - Builders

        func makeAttr(_ name: String, _ type: NSAttributeType, optional: Bool = true) -> NSAttributeDescription {
            let d = NSAttributeDescription()
            d.name = name; d.attributeType = type; d.isOptional = optional
            return d
        }

        func makeRel(name: String, destination: NSEntityDescription,
                     toMany: Bool, deleteRule: NSDeleteRule = .nullifyDeleteRule,
                     ordered: Bool = false) -> NSRelationshipDescription {
            let r = NSRelationshipDescription()
            r.name = name; r.destinationEntity = destination
            r.minCount = 0; r.maxCount = toMany ? 0 : 1
            r.isOrdered = ordered; r.deleteRule = deleteRule
            return r
        }

        // MARK: - Entity definitions

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
        ]

        // 企業内の1つの選考枠（インターン / 本選考）
        let selection = NSEntityDescription()
        selection.name = "Selection"
        selection.managedObjectClassName = "Selection"
        selection.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("category", .stringAttributeType), // インターン / 本選考
            makeAttr("title", .stringAttributeType),
            makeAttr("status", .stringAttributeType)    // 進行中/インターン参加/内定/落選/辞退
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

        // 適性検査
        let aptitudeTest = NSEntityDescription()
        aptitudeTest.name = "AptitudeTest"
        aptitudeTest.managedObjectClassName = "AptitudeTest"
        aptitudeTest.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("type", .stringAttributeType),
            makeAttr("customType", .stringAttributeType),
            makeAttr("deadlineAt", .dateAttributeType),
            makeAttr("status", .stringAttributeType)
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

        let template = NSEntityDescription()
        template.name = "Template"
        template.managedObjectClassName = "Template"
        template.properties = [
            makeAttr("id", .UUIDAttributeType),
            makeAttr("title", .stringAttributeType),
            makeAttr("content", .stringAttributeType),
            makeAttr("category", .stringAttributeType)
        ]

        // MARK: - Relationships

        // Industry <->> Company
        let indToComps = makeRel(name: "companies",  destination: company,   toMany: true,  deleteRule: .cascadeDeleteRule)
        let compToInd  = makeRel(name: "industry",   destination: industry,  toMany: false)
        indToComps.inverseRelationship = compToInd;  compToInd.inverseRelationship = indToComps
        industry.properties += [indToComps];         company.properties  += [compToInd]

        // Company <->> Selection
        let compToSels = makeRel(name: "selections", destination: selection, toMany: true,  deleteRule: .cascadeDeleteRule)
        let selToComp  = makeRel(name: "company",    destination: company,   toMany: false)
        compToSels.inverseRelationship = selToComp;  selToComp.inverseRelationship = compToSels
        company.properties   += [compToSels];        selection.properties += [selToComp]

        // Selection <->> ESBox
        let selToBoxes = makeRel(name: "esBoxes",    destination: esBox,     toMany: true,  deleteRule: .cascadeDeleteRule)
        let boxToSel   = makeRel(name: "selection",  destination: selection, toMany: false)
        selToBoxes.inverseRelationship = boxToSel;   boxToSel.inverseRelationship = selToBoxes
        selection.properties += [selToBoxes];        esBox.properties     += [boxToSel]

        // ESBox <->> ESQuestion (ordered)
        let boxToQs  = makeRel(name: "esQuestions", destination: esQuestion, toMany: true,  deleteRule: .cascadeDeleteRule, ordered: true)
        let qToBox   = makeRel(name: "esBox",       destination: esBox,      toMany: false)
        boxToQs.inverseRelationship = qToBox;        qToBox.inverseRelationship = boxToQs
        esBox.properties      += [boxToQs];          esQuestion.properties += [qToBox]

        // ESQuestion <->> ESVersion
        let qToVers  = makeRel(name: "versions",    destination: esVersion,  toMany: true,  deleteRule: .cascadeDeleteRule)
        let verToQ   = makeRel(name: "esQuestion",  destination: esQuestion, toMany: false)
        qToVers.inverseRelationship = verToQ;        verToQ.inverseRelationship = qToVers
        esQuestion.properties += [qToVers];          esVersion.properties  += [verToQ]

        // Selection <->> AptitudeTest
        let selToTests = makeRel(name: "aptitudeTests", destination: aptitudeTest, toMany: true, deleteRule: .cascadeDeleteRule)
        let testToSel  = makeRel(name: "selection",     destination: selection,    toMany: false)
        selToTests.inverseRelationship = testToSel;  testToSel.inverseRelationship = selToTests
        selection.properties   += [selToTests];      aptitudeTest.properties += [testToSel]

        // Selection <->> Interview
        let selToInts = makeRel(name: "interviews", destination: interview,  toMany: true,  deleteRule: .cascadeDeleteRule)
        let intToSel  = makeRel(name: "selection",  destination: selection,  toMany: false)
        selToInts.inverseRelationship = intToSel;    intToSel.inverseRelationship = selToInts
        selection.properties  += [selToInts];        interview.properties  += [intToSel]

        model.entities = [industry, company, selection, esBox, esQuestion, esVersion, aptitudeTest, interview, template]
        return model
    }
}
