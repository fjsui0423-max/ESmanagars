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

            if viewModel.isEmpty {
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
        List {
            if !viewModel.filteredBoxes.isEmpty {
                Section {
                    ForEach(viewModel.filteredBoxes) { box in
                        if let company = box.company {
                            NavigationLink(value: company) {
                                esBoxRow(box)
                            }
                        } else {
                            esBoxRow(box)
                        }
                    }
                } header: {
                    Label("ES締切", systemImage: "doc.text.fill")
                        .foregroundStyle(.blue)
                        .font(.subheadline.weight(.semibold))
                }
            }

            if !viewModel.filteredInterviews.isEmpty {
                Section {
                    ForEach(viewModel.filteredInterviews, id: \.objectID) { interview in
                        if let company = interview.company {
                            NavigationLink(value: company) {
                                interviewRow(interview)
                            }
                        } else {
                            interviewRow(interview)
                        }
                    }
                } header: {
                    Label("面接", systemImage: "person.2.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: Company.self) { company in
            CompanyDetailView(company: company)
        }
    }

    // MARK: - ES BOX row

    private func esBoxRow(_ box: ESBox) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(box.company?.name ?? "企業名不明")
                    .font(.subheadline.weight(.semibold))
                Text(box.title ?? "タイトルなし")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let status = box.status ?? "進行中"
            Text(status)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(status.esBoxStatusColor.opacity(0.12))
                .foregroundStyle(status.esBoxStatusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    // MARK: - Interview row

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "ja_JP")
        f.dateStyle  = .none
        f.timeStyle  = .short
        return f
    }()

    private func interviewRow(_ interview: Interview) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 18))
                .foregroundStyle(.red)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(interview.company?.name ?? "企業名不明")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(interview.stage ?? "面接")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let d = interview.startAt {
                        Text("・\(Self.timeFormatter.string(from: d))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(interview.mode ?? "")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            let status = interview.status ?? "予定"
            Text(status)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(status.interviewStatusColor.opacity(0.12))
                .foregroundStyle(status.interviewStatusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("この日の予定はありません")
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
        CalendarTaskView(context: ctx)
    }
    .environment(\.managedObjectContext, ctx)
}
#endif
