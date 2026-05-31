import SwiftUI
import UIKit
import CoreData

// MARK: - Container

struct AIExportContainerView: View {
    @Environment(\.managedObjectContext) private var context
    var body: some View {
        AIExportView(context: context)
    }
}

// MARK: - Share Sheet (iOS 15互換)

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Prompt Popup

private struct PromptPopupView: View {
    @Environment(\.dismiss) private var dismiss
    let prompt: String

    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    promptCard
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("プロンプトを確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 4) {
                Text("AIへのプロンプト")
                    .font(.headline)
                Text("以下のテキストをAIツール（ChatGPT / Gemini など）にファイルと一緒に貼り付けてください。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.08))
        .cornerRadius(12)
    }

    private var promptCard: some View {
        Text(prompt)
            .font(.callout)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                UIPasteboard.general.string = prompt
                copied = true
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    copied = false
                }
            } label: {
                Label(
                    copied ? "コピーしました！" : "プロンプトをコピー",
                    systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc"
                )
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(copied ? Color.green : Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .animation(.easeInOut(duration: 0.2), value: copied)

            Button {
                UIPasteboard.general.string = prompt
                dismiss()
            } label: {
                Text("コピーして閉じる")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Main View

struct AIExportView: View {
    @StateObject private var viewModel: AIExportViewModel

    @State private var shareURL:       URL?
    @State private var showShare       = false
    @State private var showPromptPopup = false

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: AIExportViewModel(context: context))
    }

    var body: some View {
        Form {
            filterSection
            exportSection
            howToSection
        }
        .navigationTitle("外部AI活用（プロンプト生成）")
        .navigationBarTitleDisplayMode(.large)
        // ① ファイル共有シート
        .sheet(isPresented: $showShare, onDismiss: {
            // iOS 15ではシート連続表示に短い遅延が必要
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                showPromptPopup = true
            }
        }) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        // ② プロンプト確認ポップアップ
        .sheet(isPresented: $showPromptPopup) {
            PromptPopupView(prompt: viewModel.aiPrompt)
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var filterSection: some View {
        Section {
            Toggle(isOn: $viewModel.onlyPassed) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("合格したESのみ抽出")
                    Text("内定・インターン参加・ES通過のデータのみ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("抽出条件")
        } footer: {
            Text(
                viewModel.onlyPassed
                    ? "実際に評価されたESのみを学習させることで、より精度の高い回答案を生成できます。"
                    : "提出済みのすべてのESを出力します。不合格のデータも参考として含まれます。"
            )
            .font(.footnote)
        }
    }

    private var exportSection: some View {
        Section {
            Button {
                Task {
                    guard let url = await viewModel.generateESDataFile() else { return }
                    shareURL = url
                    showShare = true
                }
            } label: {
                if viewModel.isExporting {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.accentColor)
                            .scaleEffect(0.9)
                        Text("JSONデータを出力中...")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Label("ESデータをファイル出力する", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .disabled(viewModel.isExporting)
            .animation(.easeInOut(duration: 0.15), value: viewModel.isExporting)
        } header: {
            Text("エクスポート")
        } footer: {
            Text("ESの設問と回答をMarkdown形式（.md）で出力します。共有後にAIへのプロンプトを表示します。")
                .font(.footnote)
        }
    }

    private var howToSection: some View {
        Section("使い方") {
            stepRow(number: "1", text: "「ESデータをファイル出力する」をタップしてファイルを保存・共有")
            stepRow(number: "2", text: "ChatGPT / Gemini などのAIツールを開き、ファイルを添付")
            stepRow(number: "3", text: "表示されるプロンプトをコピーしてAIに貼り付け、学習させる")
            stepRow(number: "4", text: "新しい企業の設問をAIに入力して、回答案を生成してもらう")
        }
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    NavigationStack {
        AIExportContainerView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.context)
}
#endif
