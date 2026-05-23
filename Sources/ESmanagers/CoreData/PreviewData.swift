import CoreData

enum PreviewData {
    static func populate(context: NSManagedObjectContext) {
        let tech    = Industry.create(name: "IT・通信",   sortOrder: 0, in: context)
        let finance = Industry.create(name: "金融・保険", sortOrder: 1, in: context)
        let consul  = Industry.create(name: "コンサル",   sortOrder: 2, in: context)

        let apple    = Company.create(name: "Apple",      myPageURL: "https://apple.com",     loginID: "dev@example.com", industry: tech,    in: context)
        let google   = Company.create(name: "Google",     myPageURL: "https://careers.google", industry: tech,    in: context)
        let softbank = Company.create(name: "ソフトバンク", myPageURL: "https://softbank.jp",   industry: tech,    in: context)
        let dena     = Company.create(name: "DeNA",       myPageURL: "https://dena.com",       industry: tech,    in: context)
        let mufg     = Company.create(name: "三菱UFJ",    myPageURL: "https://mufg.jp",        industry: finance, in: context)
                       Company.create(name: "野村証券",    myPageURL: "https://nomura.com",     industry: finance, in: context)
                       Company.create(name: "マッキンゼー", myPageURL: "https://mckinsey.com",  industry: consul,  in: context)
                       Company.create(name: "リクルート",  myPageURL: "https://recruit.co.jp",  in: context)

        // Keychain にプレビュー用パスワード
        if let key = apple.id?.uuidString {
            KeychainManager.shared.savePassword("Preview@pass1", for: key)
        }

        // MARK: - ESBox
        let now = Date()
        func days(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: n, to: now)! }
        func hours(_ n: Int) -> Date { Calendar.current.date(byAdding: .hour, value: n, to: now)! }

        let b1 = ESBox(context: context)
        b1.id = UUID(); b1.title = "サマーインターン"; b1.status = "進行中"
        b1.deadlineAt = days(7); b1.company = apple

        let b2 = ESBox(context: context)
        b2.id = UUID(); b2.title = "秋冬インターン"; b2.status = "未着手"
        b2.deadlineAt = days(60); b2.company = apple

        let b3 = ESBox(context: context)
        b3.id = UUID(); b3.title = "本選考"; b3.status = "未着手"
        b3.deadlineAt = days(120); b3.company = apple

        // カレンダー画面プレビュー用：今日締切
        let b4 = ESBox(context: context)
        b4.id = UUID(); b4.title = "書類選考"; b4.status = "進行中"
        b4.deadlineAt = now; b4.company = apple

        // MARK: - ESQuestion（b1 用）
        let q1 = ESQuestion(context: context)
        q1.id = UUID(); q1.sortOrder = 0; q1.maxLength = 400
        q1.questionText = "学生時代に最も力を入れて取り組んだことを、具体的なエピソードを交えて400字以内で教えてください。"
        q1.currentAnswer = "大学3年間、私はプログラミングサークルの代表として活動しました。メンバー30名をまとめながら、学内ハッカソンで優勝を目指し..."
        q1.esBox = b1

        let q2 = ESQuestion(context: context)
        q2.id = UUID(); q2.sortOrder = 1; q2.maxLength = 200
        q2.questionText = "弊社のインターンシップに応募した理由を200字以内で教えてください。"
        q2.currentAnswer = ""
        q2.esBox = b1

        // MARK: - ESVersion（q1 用）
        let v1 = ESVersion(context: context)
        v1.id = UUID(); v1.savedAnswer = "最初の下書き：大学時代に力を入れたこと..."
        v1.createdAt = days(-3); v1.esQuestion = q1

        let v2 = ESVersion(context: context)
        v2.id = UUID(); v2.savedAnswer = "改善版：大学3年間、プログラミングサークルの代表として活動。チームをまとめ学内ハッカソンで優勝を達成しました。"
        v2.createdAt = hours(-2); v2.esQuestion = q1

        // MARK: - Interviews（分析・カレンダープレビュー用）

        func interview(_ stage: String, _ status: String, _ company: Company, _ offsetDays: Int) {
            let i = Interview.create(stage: stage, startAt: days(offsetDays), mode: "オンライン", company: company, in: context)
            i.status = status
        }

        // Apple: 1次通過 → 2次通過 → 最終予定（今日 +3時間）
        interview("1次面接", "通過",  apple,   -21)
        interview("2次面接", "通過",  apple,   -14)
        let appleF = Interview.create(stage: "最終面接", startAt: hours(3), mode: "対面", company: apple, in: context)
        appleF.status = "予定"   // カレンダー今日表示にも使用

        // Google: カジュアル通過 → 1次落選
        interview("カジュアル面談", "通過", google,  -30)
        interview("1次面接",       "落選", google,  -18)

        // ソフトバンク: 1次通過 → 2次通過 → 3次落選
        interview("1次面接", "通過", softbank, -40)
        interview("2次面接", "通過", softbank, -28)
        interview("3次面接", "落選", softbank, -10)

        // DeNA: 1次通過 → 2次通過 → 最終通過
        interview("1次面接", "通過", dena, -60)
        interview("2次面接", "通過", dena, -45)
        interview("最終面接", "通過", dena, -35)

        // 三菱UFJ: カジュアル通過 → 1次予定
        interview("カジュアル面談", "通過", mufg, -5)
        let mufgI = Interview.create(stage: "1次面接", startAt: days(7), mode: "対面", company: mufg, in: context)
        mufgI.status = "予定"

        // MARK: - Template
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
