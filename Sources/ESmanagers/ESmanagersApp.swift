import SwiftUI

@main
struct ESmanagersApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistence.context)
        }
    }
}
