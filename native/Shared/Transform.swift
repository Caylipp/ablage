import Foundation

/// Umwandlungen vor dem Einsetzen (Tastatur-Aktionsleiste)
enum Transform: String, CaseIterable, Identifiable {
    case upper, lower, title, trimEmptyLines, joinLines, bullets, numbered
    var id: String { rawValue }

    var label: String {
        switch self {
        case .upper: String(localized: "GROSS")
        case .lower: String(localized: "klein")
        case .title: String(localized: "Titel")
        case .trimEmptyLines: String(localized: "Leerzeilen weg")
        case .joinLines: String(localized: "Eine Zeile")
        case .bullets: String(localized: "Aufzählung")
        case .numbered: String(localized: "Nummeriert")
        }
    }

    var symbol: String {
        switch self {
        case .upper: "textformat.size.larger"
        case .lower: "textformat.size.smaller"
        case .title: "textformat"
        case .trimEmptyLines: "line.3.horizontal.decrease"
        case .joinLines: "arrow.right.to.line"
        case .bullets: "list.bullet"
        case .numbered: "list.number"
        }
    }

    func apply(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let nonEmpty = lines.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        switch self {
        case .upper: return text.uppercased()
        case .lower: return text.lowercased()
        case .title: return text.capitalized
        case .trimEmptyLines: return lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.joined(separator: "\n")
        case .joinLines: return nonEmpty.joined(separator: " ")
        case .bullets: return nonEmpty.map { "• \($0)" }.joined(separator: "\n")
        case .numbered: return nonEmpty.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        }
    }
}
