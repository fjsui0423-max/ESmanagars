import CoreData

enum PreviewData {
    static func populate(context: NSManagedObjectContext) {
        let now = Date()
        func days(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: n, to: now)! }

        // MARK: - Inline helpers

        @discardableResult
        func makeESBox(title: String = "ES", status: String, deadline: Date?, sel: Selection) -> ESBox {
            let b = ESBox(context: context)
            b.id = UUID(); b.title = title; b.status = status
            b.deadlineAt = deadline; b.selection = sel
            return b
        }

        func makeApt(type: String, deadline: Date?, status: String = "未受験", sel: Selection) {
            let t = AptitudeTest.create(type: type, deadlineAt: deadline, selection: sel, in: context)
            t.status = status
        }

        func makeInterview(stage: String, startAt: Date, mode: String, status: String = "予定", sel: Selection) {
            let i = Interview.create(stage: stage, startAt: startAt, mode: mode, selection: sel, in: context)
            i.status = status
        }

        // MARK: - Industry

        let sier = Industry.create(name: "SIer・IT", sortOrder: 0, in: context)

        // MARK: - 15 Companies

        let fujitsu  = Company.create(name: "富士通Japan",                  industry: sier, in: context)
        let canon    = Company.create(name: "キヤノンマーケティングジャパン", industry: sier, in: context)
        let nri      = Company.create(name: "NRIシステムテクノ",             industry: sier, in: context)
        let nttdata  = Company.create(name: "NTTデータ",                    industry: sier, in: context)
        let scsk     = Company.create(name: "SCSK",                        industry: sier, in: context)
        let biprogy  = Company.create(name: "BIPROGY",                     industry: sier, in: context)
        let ctc      = Company.create(name: "伊藤忠テクノソリューションズ",  industry: sier, in: context)
        let hitachi  = Company.create(name: "日立製作所",                    industry: sier, in: context)
        let dentsuso = Company.create(name: "電通総研",                      industry: sier, in: context)
        let obic     = Company.create(name: "オービック",                    industry: sier, in: context)
        let ibm      = Company.create(name: "日本IBM",                      industry: sier, in: context)
        let simplex  = Company.create(name: "シンプレクス",                  industry: sier, in: context)
        let otsuka   = Company.create(name: "大塚商会",                      industry: sier, in: context)
        let tis      = Company.create(name: "TIS",                         industry: sier, in: context)
        let nssol    = Company.create(name: "日鉄ソリューションズ",           industry: sier, in: context)

        // MARK: - 富士通Japan（インターン ＋ 本選考）

        let fjInt = Selection.create(category: "インターン", title: "夏季インターン", company: fujitsu, in: context)
        fjInt.status = "インターン参加"
        makeESBox(status: "合格",    deadline: days(-45), sel: fjInt)
        makeApt(type: "SPI(WEB)",  deadline: days(-50), status: "合格", sel: fjInt)
        makeInterview(stage: "1次面接", startAt: days(-40), mode: "オンライン", status: "通過", sel: fjInt)
        makeInterview(stage: "最終面接", startAt: days(-35), mode: "対面",      status: "通過", sel: fjInt)

        let fjFull = Selection.create(category: "本選考", title: "エンジニア職", company: fujitsu, in: context)
        makeESBox(status: "提出済み", deadline: days(-10), sel: fjFull)
        makeApt(type: "SPI(テストセンター)", deadline: days(-5), status: "受験済み", sel: fjFull)
        makeInterview(stage: "1次面接", startAt: days(7), mode: "オンライン", sel: fjFull)

        // MARK: - キヤノンマーケティングジャパン（インターン ＋ 本選考）

        let canInt = Selection.create(category: "インターン", title: "秋季インターン", company: canon, in: context)
        canInt.status = "落選"
        makeESBox(status: "落選", deadline: days(-60), sel: canInt)
        makeApt(type: "TGWEB", deadline: days(-65), status: "落選", sel: canInt)

        let canFull = Selection.create(category: "本選考", title: "総合職", company: canon, in: context)
        makeESBox(status: "提出済み", deadline: days(-5), sel: canFull)
        makeInterview(stage: "1次面接", startAt: days(-2), mode: "オンライン", status: "通過", sel: canFull)

        // MARK: - NRIシステムテクノ（インターン ＋ 本選考）

        let nriInt = Selection.create(category: "インターン", title: "冬インターン", company: nri, in: context)
        nriInt.status = "辞退"
        makeESBox(status: "合格", deadline: days(-55), sel: nriInt)
        makeInterview(stage: "1次面接", startAt: days(-50), mode: "オンライン", status: "通過", sel: nriInt)
        makeInterview(stage: "最終面接", startAt: days(-45), mode: "対面",      status: "通過", sel: nriInt)

        let nriFull = Selection.create(category: "本選考", title: "SEコース", company: nri, in: context)
        makeESBox(status: "進行中", deadline: days(5), sel: nriFull)
        makeApt(type: "SPI(WEB)", deadline: days(10), sel: nriFull)

        // MARK: - NTTデータ（インターン ＋ 本選考）

        let nttInt = Selection.create(category: "インターン", title: "夏季インターン", company: nttdata, in: context)
        nttInt.status = "インターン参加"
        makeESBox(status: "合格", deadline: days(-70), sel: nttInt)
        makeApt(type: "CAB", deadline: days(-75), status: "合格", sel: nttInt)
        makeInterview(stage: "1次面接", startAt: days(-65), mode: "オンライン", status: "通過", sel: nttInt)
        makeInterview(stage: "最終面接", startAt: days(-60), mode: "対面",      status: "通過", sel: nttInt)

        let nttFull = Selection.create(category: "本選考", title: "ITエンジニア", company: nttdata, in: context)
        makeESBox(status: "提出済み", deadline: days(-15), sel: nttFull)
        makeApt(type: "玉手箱", deadline: days(-12), status: "受験済み", sel: nttFull)
        makeInterview(stage: "1次面接", startAt: days(-8), mode: "オンライン", status: "通過", sel: nttFull)
        makeInterview(stage: "2次面接", startAt: days(3),  mode: "対面",      sel: nttFull)

        // MARK: - SCSK（インターン ＋ 本選考）

        let scskInt = Selection.create(category: "インターン", title: "システム開発体験", company: scsk, in: context)
        scskInt.status = "落選"
        makeESBox(status: "提出遅れ", deadline: days(-40), sel: scskInt)

        let scskFull = Selection.create(category: "本選考", title: "技術職", company: scsk, in: context)
        makeESBox(status: "合格", deadline: days(-20), sel: scskFull)
        makeApt(type: "TGWEB", deadline: days(-25), status: "合格", sel: scskFull)
        makeInterview(stage: "1次面接", startAt: days(-15), mode: "オンライン", status: "通過", sel: scskFull)
        makeInterview(stage: "2次面接", startAt: days(5),   mode: "オンライン", sel: scskFull)

        // MARK: - BIPROGY（インターン ＋ 本選考）

        let bipInt = Selection.create(category: "インターン", title: "秋インターン", company: biprogy, in: context)
        bipInt.status = "インターン参加"
        makeESBox(status: "合格", deadline: days(-80), sel: bipInt)
        makeInterview(stage: "1次面接", startAt: days(-75), mode: "オンライン", status: "通過", sel: bipInt)

        let bipFull = Selection.create(category: "本選考", title: "SE職", company: biprogy, in: context)
        bipFull.status = "落選"
        makeESBox(status: "落選", deadline: days(-30), sel: bipFull)
        makeApt(type: "SPI(WEB)", deadline: days(-35), status: "落選", sel: bipFull)
        makeInterview(stage: "1次面接", startAt: days(-25), mode: "対面", status: "通過", sel: bipFull)
        makeInterview(stage: "2次面接", startAt: days(-20), mode: "対面", status: "落選", sel: bipFull)

        // MARK: - 伊藤忠テクノソリューションズ（インターン ＋ 本選考）

        let ctcInt = Selection.create(category: "インターン", title: "夏季インターン", company: ctc, in: context)
        ctcInt.status = "辞退"
        makeESBox(status: "合格", deadline: days(-50), sel: ctcInt)
        makeInterview(stage: "1次面接", startAt: days(-45), mode: "オンライン", status: "通過", sel: ctcInt)

        let ctcFull = Selection.create(category: "本選考", title: "ITエンジニア", company: ctc, in: context)
        ctcFull.status = "内定"
        makeESBox(status: "合格", deadline: days(-25), sel: ctcFull)
        makeApt(type: "GAB", deadline: days(-28), status: "合格", sel: ctcFull)
        makeInterview(stage: "1次面接", startAt: days(-20), mode: "オンライン", status: "通過", sel: ctcFull)
        makeInterview(stage: "2次面接", startAt: days(-12), mode: "対面",      status: "通過", sel: ctcFull)
        makeInterview(stage: "最終面接", startAt: days(-5),  mode: "対面",      status: "通過", sel: ctcFull)

        // MARK: - 日立製作所（インターン ＋ 本選考）

        let hitInt = Selection.create(category: "インターン", title: "インターンシップ", company: hitachi, in: context)
        hitInt.status = "インターン参加"
        makeESBox(status: "合格", deadline: days(-90), sel: hitInt)
        makeApt(type: "SPI(テストセンター)", deadline: days(-95), status: "合格", sel: hitInt)
        makeInterview(stage: "1次面接", startAt: days(-85), mode: "オンライン", status: "通過", sel: hitInt)
        makeInterview(stage: "2次面接", startAt: days(-78), mode: "対面",      status: "通過", sel: hitInt)

        let hitFull = Selection.create(category: "本選考", title: "総合職エンジニア", company: hitachi, in: context)
        makeESBox(status: "未着手", deadline: days(15), sel: hitFull)

        // MARK: - 電通総研（インターン ＋ 本選考）

        let dentsuInt = Selection.create(category: "インターン", title: "夏季インターン", company: dentsuso, in: context)
        dentsuInt.status = "落選"
        makeESBox(status: "提出遅れ", deadline: days(-55), sel: dentsuInt)

        let dentsuFull = Selection.create(category: "本選考", title: "コンサルタント", company: dentsuso, in: context)
        makeESBox(status: "提出済み", deadline: days(-8), sel: dentsuFull)
        makeApt(type: "TGWEB", deadline: days(-12), status: "受験済み", sel: dentsuFull)
        makeInterview(stage: "1次面接", startAt: days(2), mode: "オンライン", sel: dentsuFull)

        // MARK: - オービック（インターン ＋ 本選考）

        let obicInt = Selection.create(category: "インターン", title: "ビジネスインターン", company: obic, in: context)
        obicInt.status = "インターン参加"
        makeESBox(status: "合格", deadline: days(-65), sel: obicInt)
        makeInterview(stage: "1次面接", startAt: days(-60), mode: "オンライン", status: "通過", sel: obicInt)
        makeInterview(stage: "最終面接", startAt: days(-55), mode: "対面",      status: "通過", sel: obicInt)

        let obicFull = Selection.create(category: "本選考", title: "営業エンジニア", company: obic, in: context)
        makeESBox(status: "提出済み", deadline: days(-3), sel: obicFull)
        makeApt(type: "SPI(WEB)", deadline: days(7), sel: obicFull)

        // MARK: - 日本IBM（本選考のみ）

        let ibmFull = Selection.create(category: "本選考", title: "テクノロジーコンサルタント", company: ibm, in: context)
        ibmFull.status = "落選"
        makeESBox(status: "落選", deadline: days(-35), sel: ibmFull)
        makeApt(type: "GAB", deadline: days(-40), status: "落選", sel: ibmFull)
        makeInterview(stage: "1次面接", startAt: days(-30), mode: "オンライン", status: "通過", sel: ibmFull)
        makeInterview(stage: "2次面接", startAt: days(-22), mode: "オンライン", status: "落選", sel: ibmFull)

        // MARK: - シンプレクス（本選考のみ）

        let simplexFull = Selection.create(category: "本選考", title: "エンジニア職", company: simplex, in: context)
        simplexFull.status = "内定"
        makeESBox(status: "合格", deadline: days(-45), sel: simplexFull)
        makeApt(type: "CAB", deadline: days(-50), status: "合格", sel: simplexFull)
        makeInterview(stage: "1次面接", startAt: days(-40), mode: "オンライン", status: "通過", sel: simplexFull)
        makeInterview(stage: "2次面接", startAt: days(-32), mode: "オンライン", status: "通過", sel: simplexFull)
        makeInterview(stage: "最終面接", startAt: days(-20), mode: "対面",      status: "通過", sel: simplexFull)

        // MARK: - 大塚商会（本選考のみ）

        let otsukaFull = Selection.create(category: "本選考", title: "営業職", company: otsuka, in: context)
        makeESBox(status: "提出済み", deadline: days(-10), sel: otsukaFull)
        makeApt(type: "玉手箱", deadline: days(-15), status: "受験済み", sel: otsukaFull)
        makeInterview(stage: "1次面接", startAt: days(8), mode: "対面", sel: otsukaFull)

        // MARK: - TIS（本選考のみ）

        let tisFull = Selection.create(category: "本選考", title: "SEコース", company: tis, in: context)
        makeESBox(status: "未着手", deadline: days(20), sel: tisFull)
        makeApt(type: "SPI(WEB)", deadline: days(25), sel: tisFull)

        // MARK: - 日鉄ソリューションズ（本選考のみ）

        let nssolFull = Selection.create(category: "本選考", title: "ITエンジニア", company: nssol, in: context)
        makeESBox(status: "提出済み", deadline: days(-6), sel: nssolFull)
        makeApt(type: "TGWEB", deadline: days(-10), status: "合格", sel: nssolFull)
        makeInterview(stage: "1次面接", startAt: days(-3),  mode: "オンライン", status: "通過", sel: nssolFull)
        makeInterview(stage: "2次面接", startAt: days(12), mode: "対面",       sel: nssolFull)

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
