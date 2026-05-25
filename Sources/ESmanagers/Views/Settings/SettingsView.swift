import SwiftUI
import UniformTypeIdentifiers
import CoreData

// MARK: - Container

struct SettingsContainerView: View {
    @Environment(\.managedObjectContext) private var context
    var body: some View {
        SettingsView(context: context)
    }
}

// MARK: - Main view

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    @State private var exportDocument:    JSONDocument?
    @State private var showExporter       = false
    @State private var showImporter       = false
    @State private var showImportConfirm  = false
    @State private var pendingImportURL:  URL?

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(context: context))
    }

    var body: some View {
        Form {
            notificationSection
            appLockSection
            aiSection
            dataManagementSection
            securityNoteSection
            appInfoSection
        }
        .navigationTitle("設定")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        // ---- fileExporter ----
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "esmanagers_backup"
        ) { result in
            if case .failure(let error) = result {
                viewModel.presentError(error.localizedDescription)
            }
        }
        // ---- fileImporter ----
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                pendingImportURL = url
                showImportConfirm = true
            case .failure(let error):
                viewModel.presentError(error.localizedDescription)
            }
        }
        // ---- 復元確認ダイアログ ----
        .confirmationDialog(
            "データを復元しますか？",
            isPresented: $showImportConfirm,
            titleVisibility: .visible
        ) {
            Button("復元する", role: .destructive) {
                if let url = pendingImportURL {
                    viewModel.importJSON(from: url)
                    pendingImportURL = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text("現在のデータはすべて削除されます。この操作は取り消せません。")
        }
        // ---- 結果アラート ----
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    // MARK: - Sections

    private var notificationSection: some View {
        Section {
            Toggle("面接リマインド通知", isOn: $viewModel.isNotificationEnabled)
                .onChange(of: viewModel.isNotificationEnabled) { _ in
                    viewModel.onNotificationSettingChanged()
                }

            Picker("事前通知（日数）", selection: $viewModel.notificationDaysBefore) {
                ForEach(0...7, id: \.self) { days in
                    Text(days == 0 ? "通知しない" : "\(days)日前").tag(days)
                }
            }
            .disabled(!viewModel.isNotificationEnabled)
            .onChange(of: viewModel.notificationDaysBefore) { _ in
                viewModel.onNotificationSettingChanged()
            }

            Picker("直前通知（時間）", selection: $viewModel.notificationHoursBefore) {
                ForEach(0...24, id: \.self) { hours in
                    Text(hours == 0 ? "通知しない" : "\(hours)時間前").tag(hours)
                }
            }
            .disabled(!viewModel.isNotificationEnabled)
            .onChange(of: viewModel.notificationHoursBefore) { _ in
                viewModel.onNotificationSettingChanged()
            }
        } header: {
            Text("通知設定")
        } footer: {
            Text("面接の開始時刻を基準に、指定した時間前にリマインド通知を送信します。")
                .font(.footnote)
        }
    }

    private var appLockSection: some View {
        Section {
            Toggle(isOn: $viewModel.isAppLockEnabled) {
                Label("アプリロック（Face ID / Touch ID）", systemImage: "faceid")
            }
            .disabled(!BiometricAuthManager.shared.isAvailable)
            if !BiometricAuthManager.shared.isAvailable {
                Text("このデバイスでは生体認証を利用できません")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("セキュリティ")
        } footer: {
            Text("有効にすると、アプリ起動時に Face ID / Touch ID による認証が必要になります。")
                .font(.footnote)
        }
    }

    private var aiSection: some View {
        Section("外部AI活用（プロンプト生成）") {
            NavigationLink {
                AIExportContainerView()
            } label: {
                Label("AIにESを学習させる", systemImage: "sparkles")
            }
        }
    }

    private var dataManagementSection: some View {
        Section("データ管理") {
            Button {
                if let doc = viewModel.exportJSON() {
                    exportDocument = doc
                    showExporter   = true
                }
            } label: {
                Label("データのバックアップ（エクスポート）", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                showImporter = true
            } label: {
                Label("データの復元（インポート）", systemImage: "square.and.arrow.down")
            }
        }
    }

    private var securityNoteSection: some View {
        Section {
            Label {
                Text("セキュリティ保護のため、バックアップにマイページログインパスワードは含まれません。復元後に再度登録してください。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("セキュリティに関する注記")
        }
    }

    private var appInfoSection: some View {
        Section("アプリ情報") {
            LabeledContent("バージョン", value: appVersion)
            LabeledContent("ビルド",     value: buildNumber)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    NavigationStack {
        SettingsContainerView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.context)
}
#endif
