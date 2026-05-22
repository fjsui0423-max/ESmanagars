import SwiftUI
import CoreData

// MARK: - Container

struct CalendarTaskContainerView: View {
    @Environment(\.managedObjectContext) private var context
    var body: some View {
        CalendarTaskView(context: context)
    }
}

// MARK: - Main view

struct CalendarTaskView: View {
    @StateObject private var viewModel: CalendarTaskViewModel

    init(context: NSManagedObjectContext, previewDate: Date? = nil) {
        _viewModel = StateObject(
            wrappedValue: CalendarTaskViewModel(
                context: context,
                initialDate: previewDate ?? Date()
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            DatePicker(
                "日付を選択",
                selection: $viewModel.selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal, 8)
            .padding(.bottom, 4)

            Divider()

            if viewModel.filteredBoxes.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .background(Color.systemGroupedBackground.ignoresSafeArea())
        .navigationTitle("カレンダー")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear { viewModel.fetch() }
    }

    // MARK: - Task list

    private var taskList: some View {
        List(viewModel.filteredBoxes) { box in
            NavigationLink {
                if let company = box.company {
                    CompanyDetailView(company: company)
                } else {
                    Text("企業が見つかりません").foregroundStyle(.secondary)
                }
            } label: {
                taskRow(box)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func taskRow(_ box: ESBox) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(box.company?.name ?? "企業名不明")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 8) {
                Text(box.title ?? "タイトルなし")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let status = box.status ?? "未着手"
                Text(status)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(status.esBoxStatusColor.opacity(0.12))
                    .foregroundStyle(status.esBoxStatusColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("この日の締切タスクはありません")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#if os(iOS)
#Preview {
    let ctx = PersistenceController.preview.context
    return NavigationStack {
        // 今日締切のデータ（PreviewData b4）が表示される
        CalendarTaskView(context: ctx)
    }
    .environment(\.managedObjectContext, ctx)
}
#endif
