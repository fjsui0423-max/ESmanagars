import SwiftUI

struct MainTabView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var isUnlocked        = false
    @State private var showPrivacyScreen = false
    @State private var isAuthenticating  = false

    var body: some View {
        ZStack {
            tabContent
                .opacity(showPrivacyScreen ? 0 : 1)

            if showPrivacyScreen {
                privacyScreen
            }
        }
        .task {
            if isAppLockEnabled {
                showPrivacyScreen = true
                await authenticate()
            } else {
                isUnlocked = true
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background, .inactive:
                if isAppLockEnabled { showPrivacyScreen = true }
            case .active:
                if isAppLockEnabled && !isUnlocked && !isAuthenticating {
                    Task { await authenticate() }
                }
            @unknown default:
                break
            }
        }
    }

    // MARK: - Privacy screen

    private var privacyScreen: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("ESmanagers")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                if !isAuthenticating {
                    Button {
                        Task { await authenticate() }
                    } label: {
                        Label("認証する", systemImage: "faceid")
                            .font(.body.weight(.medium))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .transition(.opacity)
    }

    // MARK: - Auth

    private func authenticate() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        let success = await BiometricAuthManager.shared.authenticate(
            reason: "ESmanagersのデータにアクセスするために認証が必要です"
        )
        isAuthenticating = false
        if success {
            isUnlocked = true
            withAnimation(.easeOut(duration: 0.2)) { showPrivacyScreen = false }
        }
    }

    // MARK: - Tabs

    private var tabContent: some View {
        TabView {
            NavigationStack {
                HomeViewContainer()
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }

            NavigationStack {
                CalendarTaskContainerView()
            }
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }

            NavigationStack {
                TemplateListContainerView()
            }
            .tabItem {
                Label("テンプレート", systemImage: "doc.text.fill")
            }

            NavigationStack {
                AnalyticsContainerView()
            }
            .tabItem {
                Label("分析", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SettingsContainerView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
        }
        .onAppear {
            Task { await NotificationManager.shared.requestAuthorization() }
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
