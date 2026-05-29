import SwiftUI
import GoogleMobileAds

@main
struct ESmanagersApp: App {
    let persistence = PersistenceController.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // GADMobileAds の初期化が完了してから広告をロードする。
        // ここが抜けると GAD 未初期化のままロードが走り、isLoading が永久に true になる。
        GADMobileAds.sharedInstance().start { _ in
            AdMobRewardManager.shared.loadRewardAd()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistence.context)
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .background || phase == .inactive else { return }
            let ctx = persistence.context
            guard ctx.hasChanges else { return }
            try? ctx.save()
        }
    }
}
