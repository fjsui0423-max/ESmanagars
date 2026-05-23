import CoreData

enum PreviewData {
    static func populate(context: NSManagedObjectContext) {

        // MARK: - Industries & Companies

        let tech    = Industry.create(name: "IT・通信",   sortOrder: 0, in: context)
        let finance = Industry.create(name: "金融・保険", sortOrder: 1, in: context)
        let consul  = Industry.create(name: "コンサル",   sortOrder: 2, in: context)

        let apple    = Company.create(name: "Apple",      myPageURL: "https://apple.com",      loginID: "dev@example.com", industry: tech,    in: context)
        let google   = Company.create(name: "Google",     myPageURL: "https://careers.google", industry: tech,    in: context)
        let softbank = Company.create(name: "ソフトバンク", myPageURL: "https://softbank.jp",    industry: tech,    in: context)
        let dena     = Company.create(name: "DeNA",       myPageURL: "https://dena.com",        industry: tech,    in: context)
        let mufg     = Company.create(name: "三菱UFJ",    myPageURL: "https://mufg.jp",         industry: finance, in: context)
                       Company.create(name: "野村証券",    myPageURL: "https://nomura.com",      industry: finance, in: context)
                       Company.create(name: "マッキンゼー", myPageURL: "https://mckinsey.com",   industry: consul,  in: context)
                       Company.create(name: "リクルート",  myPageURL: "https://recruit.co.jp",  in: context)

        if let key = apple.id?.uuidString {
            KeychainManager.shared.savePassword("Preview@pass1", for: key)
        }

        let now = Date()
        func days(_ n: Int) -> Date  { Calendar.current.date(byAdding: .day,  value: n, to: now)! }
        func hours(_ n: Int) -> Date { Calendar.current.date(byAdding: .hour, value: n, to: now)! }

        // MARK: - Apple: サマーインターン選考

        let appleIntern = Selection.create(category: "インターン", title: "サマーインターン", company: apple, in: context)

        // ESBox
        let b1 = ESBox(context: context)
        b1.id = UUID(); b1.title = "ES"; b1.status = "進行中"
        b1.deadlineAt = days(7); b1.selection = appleIntern

        let q1 = ESQuestion(context: context)
        q1.id = UUID(); q1.sortOrder = 0; q1.maxLength = 400
        q1.questionText  = "学生時代に最も力を入れて取り組んだことを、具体的なエピソードを交えて400字以内で教えてください。"
        q1.currentAnswer = "大学3年間、私はプログラミングサークルの代表として活動しました。メンバー30名をまとめながら、学内ハッカソンで優勝を目指し..."
        q1.esBox = b1

        let q2 = ESQuestion(context: context)
        q2.id = UUID(); q2.sortOrder = 1; q2.maxLength = 200
        q2.questionText  = "弊社のインターンシップに応募した理由を200字以内で教えてください。"
        q2.currentAnswer = ""
        q2.esBox = b1

        let v1 = ESVersion(context: context)
        v1.id = UUID(); v1.savedAnswer = "最初の下書き：大学時代に力を入れたこと..."
        v1.createdAt = days(-3); v1.esQuestion = q1

        let v2 = ESVersion(context: context)
        v2.id = UUID(); v2.savedAnswer = "改善版：大学3年間、プログラミングサークルの代表として活動。チームをまとめ学内ハッカソンで優勝を達成しました。"
        v2.createdAt = hours(-2); v2.esQuestion = q1

        // AptitudeTest
        let at1 = AptitudeTest(context: context)
        at1.id = UUID(); at1.type = "SPI(WEB)"; at1.status = "未受験"
        at1.deadlineAt = days(14); at1.selection = appleIntern

        // Interviews
        let ai1 = Interview(context: context)
        ai1.id = UUID(); ai1.stage = "1次面接"; ai1.status = "通過"
        ai1.startAt = days(-21); ai1.mode = "オンライン"; ai1.selection = appleIntern

        let ai2 = Interview(context: context)
        ai2.id = UUID(); ai2.stage = "2次面接"; ai2.status = "通過"
        ai2.startAt = days(-14); ai2.mode = "オンライン"; ai2.selection = appleIntern

        let ai3 = Interview(context: context)
        ai3.id = UUID(); ai3.stage = "最終面接"; ai3.status = "予定"
        ai3.startAt = hours(3); ai3.mode = "対面"; ai3.selection = appleIntern

        // MARK: - Apple: 本選考

        let appleFull = Selection.create(category: "本選考", title: "エンジニア本選考", company: apple, in: context)

        let b2 = ESBox(context: context)
        b2.id = UUID(); b2.title = "ES"; b2.status = "未着手"
        b2.deadlineAt = days(60); b2.selection = appleFull

        // MARK: - Google: 本選考

        let googleFull = Selection.create(category: "本選考", title: "ソフトウェアエンジニア", company: google, in: context)

        let gi1 = Interview(context: context)
        gi1.id = UUID(); gi1.stage = "カジュアル面談"; gi1.status = "通過"
        gi1.startAt = days(-30); gi1.mode = "オンライン"; gi1.selection = googleFull

        let gi2 = Interview(context: context)
        gi2.id = UUID(); gi2.stage = "1次面接"; gi2.status = "落選"
        gi2.startAt = days(-18); gi2.mode = "オンライン"; gi2.selection = googleFull
        googleFull.status = "落選"

        // MARK: - ソフトバンク: インターン

        let sbIntern = Selection.create(category: "インターン", title: "ビジネス体験インターン", company: softbank, in: context)

        let si1 = Interview(context: context)
        si1.id = UUID(); si1.stage = "1次面接"; si1.status = "通過"
        si1.startAt = days(-40); si1.mode = "オンライン"; si1.selection = sbIntern

        let si2 = Interview(context: context)
        si2.id = UUID(); si2.stage = "2次面接"; si2.status = "通過"
        si2.startAt = days(-28); si2.mode = "オンライン"; si2.selection = sbIntern

        let si3 = Interview(context: context)
        si3.id = UUID(); si3.stage = "3次面接"; si3.status = "落選"
        si3.startAt = days(-10); si3.mode = "対面"; si3.selection = sbIntern
        sbIntern.status = "落選"

        // MARK: - DeNA: 本選考（内定）

        let denaFull = Selection.create(category: "本選考", title: "エンジニア職", company: dena, in: context)

        let di1 = Interview(context: context)
        di1.id = UUID(); di1.stage = "1次面接"; di1.status = "通過"
        di1.startAt = days(-60); di1.mode = "オンライン"; di1.selection = denaFull

        let di2 = Interview(context: context)
        di2.id = UUID(); di2.stage = "2次面接"; di2.status = "通過"
        di2.startAt = days(-45); di2.mode = "オンライン"; di2.selection = denaFull

        let di3 = Interview(context: context)
        di3.id = UUID(); di3.stage = "最終面接"; di3.status = "通過"
        di3.startAt = days(-35); di3.mode = "対面"; di3.selection = denaFull
        denaFull.status = "内定"

        // MARK: - 三菱UFJ: 本選考（進行中）

        let mufgFull = Selection.create(category: "本選考", title: "総合職", company: mufg, in: context)

        let at2 = AptitudeTest(context: context)
        at2.id = UUID(); at2.type = "SPI(テストセンター)"; at2.status = "受験済み"
        at2.deadlineAt = days(-3); at2.selection = mufgFull

        let mi1 = Interview(context: context)
        mi1.id = UUID(); mi1.stage = "カジュアル面談"; mi1.status = "通過"
        mi1.startAt = days(-5); mi1.mode = "オンライン"; mi1.selection = mufgFull

        let mi2 = Interview(context: context)
        mi2.id = UUID(); mi2.stage = "1次面接"; mi2.status = "予定"
        mi2.startAt = days(7); mi2.mode = "対面"; mi2.selection = mufgFull

        // MARK: - Templates

        let t1 = Template(context: context)
        t1.id = UUID(); t1.title = "自己PR（行動力）"; t1.category = "自己PR"
        t1.content = "私の強みは、課題に対して素早く行動できることです。〇〇の経験において、問題が発覚した際に即座に〇〇という対策を講じ、△△という成果を達成しました。"

        let t2 = Template(context: context)
        t2.id = UUID(); t2.title = "志望動機（テクノロジー）"; t2.category = "志望動機"
        t2.content = "貴社を志望する理由は、〇〇というビジョンに強く共感したからです。特に△△の事業において、私の〇〇という強みを活かせると確信しています。"

        let t3 = Template(context: context)
        t3.id = UUID(); t3.title = "ガクチカ（研究）"; t3.category = "学生時代"
        t3.content = "学生時代に最も力を入れたことは研究活動です。〇〇という研究テーマに取り組み、▲▲という困難に直面しましたが、〇〇という工夫で乗り越えました。"

        try? context.save()
    }
}
