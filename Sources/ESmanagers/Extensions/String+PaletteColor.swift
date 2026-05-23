import SwiftUI

extension String {

    // MARK: - Selection status

    var selectionStatusColor: Color {
        switch self {
        case "進行中":       return .blue
        case "インターン参加": return .teal
        case "内定":         return .green
        case "落選":         return .red
        case "辞退":         return .orange
        default:             return .gray
        }
    }

    // MARK: - ESBox status

    var esBoxStatusColor: Color {
        switch self {
        case "未着手":   return .gray
        case "進行中":   return .blue
        case "提出済み":  return .teal
        case "提出遅れ":  return .orange
        case "合格":     return .green
        case "落選":     return .red
        default:         return .gray
        }
    }

    // MARK: - AptitudeTest status

    var aptitudeStatusColor: Color {
        switch self {
        case "未受験":   return .gray
        case "受験済み":  return .blue
        case "合格":     return .green
        case "落選":     return .red
        default:         return .gray
        }
    }

    // MARK: - Interview status

    var interviewStatusColor: Color {
        switch self {
        case "予定": return .blue
        case "通過": return .green
        case "落選": return .red
        case "辞退": return .orange
        default:     return .gray
        }
    }

    // MARK: - Company palette color

    /// 文字列のハッシュ値からアイコン用パレットカラーを返す
    var paletteColor: Color {
        let palette: [Color] = [
            Color(red: 0.25, green: 0.47, blue: 0.85),
            Color(red: 0.20, green: 0.72, blue: 0.60),
            Color(red: 0.90, green: 0.45, blue: 0.25),
            Color(red: 0.65, green: 0.25, blue: 0.80),
            Color(red: 0.85, green: 0.25, blue: 0.45),
            Color(red: 0.20, green: 0.60, blue: 0.40),
            Color(red: 0.55, green: 0.35, blue: 0.85),
            Color(red: 0.85, green: 0.60, blue: 0.15),
            Color(red: 0.15, green: 0.55, blue: 0.75),
            Color(red: 0.70, green: 0.30, blue: 0.60)
        ]
        let hash = unicodeScalars.reduce(0) { acc, scalar in acc &+ Int(scalar.value) }
        return palette[abs(hash) % palette.count]
    }
}
