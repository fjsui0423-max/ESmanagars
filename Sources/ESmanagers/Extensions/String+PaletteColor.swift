import SwiftUI

extension String {
    var esBoxStatusColor: Color {
        switch self {
        case "進行中":     return .blue
        case "書類選考中": return .purple
        case "提出済み":   return .orange
        case "合格":       return .green
        case "不合格", "辞退": return .red
        default:           return .gray
        }
    }

    /// 文字列のハッシュ値からアイコン用パレットカラーを返す
    var paletteColor: Color {
        let palette: [Color] = [
            Color(red: 0.25, green: 0.47, blue: 0.85), // indigo blue
            Color(red: 0.20, green: 0.72, blue: 0.60), // teal green
            Color(red: 0.90, green: 0.45, blue: 0.25), // warm orange
            Color(red: 0.65, green: 0.25, blue: 0.80), // purple
            Color(red: 0.85, green: 0.25, blue: 0.45), // rose
            Color(red: 0.20, green: 0.60, blue: 0.40), // emerald
            Color(red: 0.55, green: 0.35, blue: 0.85), // violet
            Color(red: 0.85, green: 0.60, blue: 0.15), // amber
            Color(red: 0.15, green: 0.55, blue: 0.75), // sky blue
            Color(red: 0.70, green: 0.30, blue: 0.60)  // pink-purple
        ]
        let hash = unicodeScalars.reduce(0) { acc, scalar in acc &+ Int(scalar.value) }
        return palette[abs(hash) % palette.count]
    }
}
