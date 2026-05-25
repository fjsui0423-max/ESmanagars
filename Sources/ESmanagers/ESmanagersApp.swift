import SwiftUI

@main
struct ESmanagersApp: App {
    let persistence = PersistenceController.shared
    @Environment(\.scenePhase) private var scenePhase

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
