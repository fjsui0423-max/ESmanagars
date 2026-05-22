import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ToastView(message: "IDをコピーしました")
        .padding()
}
