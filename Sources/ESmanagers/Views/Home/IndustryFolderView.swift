import SwiftUI

struct IndustryFolderView: View {
    @ObservedObject var industry: Industry

    private let iconSize: CGFloat = 68
    private let miniIconSize: CGFloat = 22

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Folder body
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(folderBackground)
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

                // Mini company icons grid
                miniIconGrid
                    .padding(10)
            }

            Text(industry.name ?? "")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(width: iconSize)
        }
    }

    // MARK: - Mini 2x2 icon grid

    @ViewBuilder
    private var miniIconGrid: some View {
        let companies = Array(industry.companiesArray.prefix(4))

        if companies.isEmpty {
            Image(systemName: "folder")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)
        } else {
            let rows = stride(from: 0, to: min(companies.count, 4), by: 2).map { i in
                Array(companies[i..<min(i + 2, companies.count)])
            }
            VStack(spacing: 5) {
                ForEach(rows.indices, id: \.self) { rowIdx in
                    HStack(spacing: 5) {
                        ForEach(rows[rowIdx], id: \.objectID) { company in
                            miniIcon(for: company)
                        }
                    }
                }
            }
        }
    }

    private func miniIcon(for company: Company) -> some View {
        ZStack {
            Circle()
                .fill((company.name ?? "").paletteColor)
                .frame(width: miniIconSize, height: miniIconSize)
            Text(String((company.name ?? "?").prefix(1)))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Folder background

    private var folderBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.85, green: 0.87, blue: 0.92),
                Color(red: 0.75, green: 0.78, blue: 0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview {
    let ctx = PersistenceController.preview.context
    let industry = (try? Industry.fetchAll(in: ctx))?.first!
    return IndustryFolderView(industry: industry!)
        .padding()
}
