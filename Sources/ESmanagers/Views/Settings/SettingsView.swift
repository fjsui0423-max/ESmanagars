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
