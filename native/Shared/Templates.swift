import Foundation

/// Platzhalter in Bausteinen, ersetzt beim Einsetzen bzw. Kopieren.
/// {Datum} {Uhrzeit} {Wochentag} {Zwischenablage} {Cursor} – englisch: {date} {time} {weekday} {clipboard} {cursor}
enum Templates {
    static let placeholders = ["{Datum}", "{Uhrzeit}", "{Wochentag}", "{Zwischenablage}", "{Cursor}"]

    static func hasPlaceholders(_ text: String) -> Bool {
        text.range(of: #"\{(datum|date|uhrzeit|time|wochentag|weekday|zwischenablage|clipboard|cursor)\}"#,
                   options: [.regularExpression, .caseInsensitive]) != nil
    }

    static func needsClipboard(_ text: String) -> Bool {
        text.range(of: #"\{(zwischenablage|clipboard)\}"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Liefert den fertigen Text und – falls {Cursor} vorkommt – wie viele Zeichen der Cursor vom Ende zurück muss.
    static func expand(_ text: String, now: Date = Date(), locale: Locale = .current, clipboard: String? = nil) -> (String, Int?) {
        guard hasPlaceholders(text) else { return (text, nil) }
        func fmt(_ date: DateFormatter.Style, _ time: DateFormatter.Style) -> String {
            let f = DateFormatter()
            f.locale = locale
            f.dateStyle = date
            f.timeStyle = time
            return f.string(from: now)
        }
        let weekday: String = {
            let f = DateFormatter()
            f.locale = locale
            f.dateFormat = "EEEE"
            return f.string(from: now)
        }()
        let values: [(String, String)] = [
            ("datum", fmt(.medium, .none)), ("date", fmt(.medium, .none)),
            ("uhrzeit", fmt(.none, .short)), ("time", fmt(.none, .short)),
            ("wochentag", weekday), ("weekday", weekday),
            ("zwischenablage", clipboard ?? ""), ("clipboard", clipboard ?? ""),
        ]
        var out = text
        for (name, value) in values {
            out = out.replacingOccurrences(of: "{\(name)}", with: value, options: .caseInsensitive)
        }
        var back: Int?
        if let r = out.range(of: #"\{(cursor)\}"#, options: [.regularExpression, .caseInsensitive]) {
            back = out.distance(from: r.upperBound, to: out.endIndex)
            out.removeSubrange(r)
            out = out.replacingOccurrences(of: #"\{cursor\}"#, with: "", options: [.regularExpression, .caseInsensitive])
        }
        return (out, back)
    }
}
