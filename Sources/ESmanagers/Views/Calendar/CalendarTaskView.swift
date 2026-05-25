import SwiftUI
import CoreData

// MARK: - Container

struct CalendarTaskContainerView: View {
    @Environment(\.managedObjectContext) private var context
    var body: some View {
        CalendarTaskView(context: context)
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date:           Date
    let isSelected:     Bool
    let isToday:        Bool
    let isCurrentMonth: Bool
    let boxes:          [ESBox]
    let aptitudeTests:  [AptitudeTest]
    let interviews:     [Interview]
    let onTap:          () -> Void

    private var dayNumber: Int { Calendar.current.component(.day,     from: date) }
    private var weekday:   Int { Calendar.current.component(.weekday, from: date) }

    private var dayTextColor: Color {
        if isSelected      { return .white }
        if !isCurrentMonth { return Color.secondary.opacity(0.4) }
        if weekday == 1    { return .red }
        if weekday == 7    { return .blue }
        return .primary
    }

    var body: some View {
        VStack(spacing: 2) {
            dayCircle
            taskLabels
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.horizontal, 1)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var dayCircle: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 26, height: 26)
            } else if isToday {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 1.5)
                    .frame(width: 26, height: 26)
            }
            Text("\(dayNumber)")
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(dayTextColor)
        }
        .frame(height: 27)
    }

    @ViewBuilder
    private var taskLabels: some View {
        ForEach(Array(boxes.prefix(1))) { box in
            Text("ES:\(box.selection?.company?.name ?? "")")
                .font(.system(size: 9))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.15))
                .foregroundStyle(Color.blue)
                .cornerRadius(2)
        }
        ForEach(Array(aptitudeTests.prefix(1))) { test in
            Text("適:\(test.selection?.company?.name ?? "")")
                .font(.system(size: 9))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.15))
                .foregroundStyle(Color.orange)
                .cornerRadius(2)
        }
        ForEach(Array(interviews.prefix(1))) { interview in
            Text("面:\(interview.selection?.company?.name ?? "")")
                .font(.system(size: 9))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.15))
                .foregroundStyle(Color.red)
                .cornerRadius(2)
        }
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

    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns  = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f
    }()

    var body: some View {
        // カレンダーとタスクリストを一体でスクロール
        ScrollView {
            VStack(spacing: 0) {
                calendarHeader
                weekdayHeader
                calendarGrid
                Divider()
                if viewModel.isEmpty {
                    emptyState
                } else {
                    taskSections
                }
            }
        }
        .background(Color.systemGroupedBackground.ignoresSafeArea())
        .navigationTitle("カレンダー")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(for: Company.self) { company in
            CompanyDetailView(company: company)
        }
        .onAppear { viewModel.fetch() }
    }

    // MARK: - Calendar header

    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.moveToPreviousMonth() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }

            Spacer()

            Text(Self.monthFormatter.string(from: viewModel.currentMonth))
                .font(.headline)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.moveToNextMonth() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        day == "日" ? Color.red :
                        day == "土" ? Color.blue :
                        Color.secondary
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
        .padding(.horizontal, 4)
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(viewModel.calendarDates, id: \.self) { date in
                DayCell(
                    date:           date,
                    isSelected:     viewModel.isSelected(date),
                    isToday:        viewModel.isToday(date),
                    isCurrentMonth: viewModel.isCurrentMonth(date),
                    boxes:          viewModel.boxes(for: date),
                    aptitudeTests:  viewModel.aptitudeTests(for: date),
                    interviews:     viewModel.interviews(for: date),
                    onTap:          { viewModel.selectedDate = date }
                )
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    // MARK: - Task sections (全体スクロールに統合)

    private var taskSections: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !viewModel.filteredBoxes.isEmpty {
                taskSectionLabel("ES締切", icon: "doc.text.fill", color: .blue)
                taskGroup {
                    let items = viewModel.filteredBoxes
                    ForEach(0 ..< items.count, id: \.self) { i in
                        taskNavigationRow(company: items[i].selection?.company) {
                            esBoxRow(items[i])
                        }
                        if i < items.count - 1 {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
            }

            if !viewModel.filteredAptitudeTests.isEmpty {
                taskSectionLabel("適性検査締切", icon: "checkmark.circle.fill", color: .orange)
                taskGroup {
                    let items = viewModel.filteredAptitudeTests
                    ForEach(0 ..< items.count, id: \.self) { i in
                        taskNavigationRow(company: items[i].selection?.company) {
                            aptitudeTestRow(items[i])
                        }
                        if i < items.count - 1 {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
            }

            if !viewModel.filteredInterviews.isEmpty {
                taskSectionLabel("面接", icon: "person.2.fill", color: .red)
                taskGroup {
                    let items = viewModel.filteredInterviews
                    ForEach(0 ..< items.count, id: \.self) { i in
                        taskNavigationRow(company: items[i].selection?.company) {
                            interviewRow(items[i])
                        }
                        if i < items.count - 1 {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 32)
    }

    // MARK: - Task section helpers

    private func taskSectionLabel(_ title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .foregroundStyle(color)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private func taskGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func taskNavigationRow<Content: View>(
        company: Company?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if let company {
            NavigationLink(value: company) { content() }
                .buttonStyle(.plain)
        } else {
            content()
        }
    }

    // MARK: - ES BOX row

    private func esBoxRow(_ box: ESBox) -> some View {
        let status = box.status ?? "未着手"
        let active = status == "未着手" || status == "進行中"
        return HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(box.selection?.company?.name ?? "企業名不明")
                    .font(.subheadline.weight(.semibold))
                Text(box.title ?? "タイトルなし")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(status)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(status.esBoxStatusColor.opacity(0.12))
                .foregroundStyle(status.esBoxStatusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .opacity(active ? 1.0 : 0.5)
    }

    // MARK: - AptitudeTest row

    private func aptitudeTestRow(_ test: AptitudeTest) -> some View {
        let status = test.status ?? "未受験"
        let active = status == "未受験" || status == "受験済み"
        return HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(test.selection?.company?.name ?? "企業名不明")
                    .font(.subheadline.weight(.semibold))
                Text(test.displayType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(status)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(status.aptitudeStatusColor.opacity(0.12))
                .foregroundStyle(status.aptitudeStatusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .opacity(active ? 1.0 : 0.5)
    }

    // MARK: - Interview row

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale    = Locale(identifier: "ja_JP")
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private func interviewRow(_ interview: Interview) -> some View {
        let status = interview.status ?? "予定"
        let active = status == "予定"
        return HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 18))
                .foregroundStyle(.red)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(interview.selection?.company?.name ?? "企業名不明")
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
                    if let mode = interview.mode, !mode.isEmpty {
                        Text(mode)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(status)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(status.interviewStatusColor.opacity(0.12))
                .foregroundStyle(status.interviewStatusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .opacity(active ? 1.0 : 0.5)
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
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
