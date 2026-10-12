import Foundation

/// Typerkennung und Fingerabdruck (Port von v1 src/lib/detect.ts).
enum Detect {
    private static func re(_ p: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: p, options: [.caseInsensitive, .anchorsMatchLines])
    }

    private static let color = re(#"^(#([0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})|rgba?\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*(,\s*(0|1|0?\.\d+)\s*)?\)|hsla?\(\s*\d{1,3}(deg)?\s*,\s*\d{1,3}%\s*,\s*\d{1,3}%\s*(,\s*(0|1|0?\.\d+)\s*)?\))$"#)
    private static let email = re(#"^[^\s@]+@[^\s@]+\.[a-z]{2,}$"#)
    private static let link = re(#"^(https?://|www\.)[^\s]+$|^[a-z0-9-]+(\.[a-z0-9-]+)*\.(com|de|org|net|io|dev|app|at|ch|eu|co|me|info)(/[^\s]*)?$"#)
    private static let phone = re(#"^\+?[\d\s()/-]{6,20}$"#)
    private static let codeHints = [
        re(#"[{};]\s*$"#),
        re(#"^\s*(const|let|var|function|import|export|return|def|class|if|for|while|public|private|func|struct|#include|SELECT|FROM)\b"#),
        re(#"=>|::|\(\)\s*\{|</?[a-z][\w-]*[^>]*>"#),
    ]

    private static func matches(_ r: NSRegularExpression, _ s: String) -> Bool {
        r.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }

    static func kind(_ raw: String) -> ClipKind {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return .text }
        let single = !t.contains("\n")
        if single && matches(color, t) { return .color }
        if single && matches(email, t) { return .email }
        if single && matches(link, t) { return .link }
        if single && matches(phone, t) && t.filter(\.isNumber).count >= 6 { return .phone }
        let hits = codeHints.filter { matches($0, t) }.count
        if hits >= 2 || (hits >= 1 && !single) { return .code }
        return .text
    }

    static func url(_ text: String) -> URL? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: t.lowercased().hasPrefix("http") ? t : "https://\(t)")
    }

    static func domain(_ text: String) -> String {
        var h = url(text)?.host ?? text
        if h.hasPrefix("www.") { h.removeFirst(4) }
        return h
    }

    /// FNV-1a 64 Bit über die Bytes + Länge, Präfix trennt Text/Bild/Datei
    static func hash(_ text: String) -> String { hash(Data(text.utf8), prefix: "t") }

    static func hash(_ data: Data, prefix: String) -> String {
        var h: UInt64 = 0xcbf29ce484222325
        for b in data {
            h ^= UInt64(b)
            h = h &* 0x100000001b3
        }
        return "\(prefix):\(data.count):\(String(h, radix: 16))"
    }

    static func describe(_ c: Clip) -> String {
        switch c.kind {
        case .image:
            if let w = c.imageWidth, let h = c.imageHeight { return "\(Int(w)) × \(Int(h))" }
            return "Bild"
        case .file: return c.fileName ?? "Datei"
        default:
            let words = (c.text ?? "").split(whereSeparator: \.isWhitespace).count
            return words > 1 ? "\(words) Wörter" : "\((c.text ?? "").count) Zeichen"
        }
    }

    static func relative(_ d: Date, now: Date = Date()) -> String {
        let s = max(0, Int(now.timeIntervalSince(d)))
        if s < 60 { return "gerade eben" }
        if s < 3600 { return "vor \(s / 60) Min." }
        if s < 86400 { return "vor \(s / 3600) Std." }
        let days = s / 86400
        if days == 1 { return "gestern" }
        if days < 7 { return "vor \(days) Tagen" }
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yy"
        return f.string(from: d)
    }
}
