import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // MARK: ホーム
            NavigationStack {
                HomeViewContainer()
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }

            // MARK: カレンダー
            NavigationStack {
                CalendarTaskContainerView()
            }
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }

            // MARK: テンプレート
            NavigationStack {
                TemplateListContainerView()
            }
            .tabItem {
                Label("テンプレート", systemImage: "doc.text.fill")
            }

            // MARK: 設定
            NavigationStack {
                SettingsContainerView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
        }
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.context)
}
#endif
