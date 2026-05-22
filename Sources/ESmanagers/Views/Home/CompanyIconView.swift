import SwiftUI

struct CompanyIconView: View {
    let company: Company

    private let iconSize: CGFloat = 68

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [iconColor, iconColor.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: iconColor.opacity(0.35), radius: 4, x: 0, y: 2)

                Text(initial)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(company.name ?? "")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: iconSize)
        }
    }

    private var initial: String {
        String((company.name ?? "?").prefix(1))
    }

    private var iconColor: Color {
        (company.name ?? "").paletteColor
    }
}

// MARK: - Preview

#Preview {
    let ctx = PersistenceController.preview.context
    let company = (try? Company.fetchAll(in: ctx))?.first!
    return CompanyIconView(company: company!)
        .padding()
}
