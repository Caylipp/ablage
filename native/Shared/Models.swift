import Foundation

enum ClipKind: String, Codable, CaseIterable, Identifiable {
    case text, link, image, color, email, phone, code, file
    var id: String { rawValue }

    var label: String {
        switch self {
        case .text: String(localized: "Text")
        case .link: String(localized: "Link")
        case .image: String(localized: "Bild")
        case .color: String(localized: "Farbe")
        case .email: String(localized: "E-Mail")
        case .phone: String(localized: "Telefon")
        case .code: String(localized: "Code")
        case .file: String(localized: "Datei")
        }
    }
}

struct Clip: Codable, Identifiable, Equatable {
    var id: String
    var kind: ClipKind
    var text: String?
    /// Dateiname im images/-Ordner (Original) bzw. Vorschau (klein, für die Tastatur)
    var imageFile: String?
    var thumbFile: String?
    var imageWidth: Double?
    var imageHeight: Double?
    var fileName: String?
    var hash: String
    var createdAt: Date
    var usedAt: Date
    var title: String?
    var pinboardIds: [String] = []
    var isNote: Bool = false
    /// Sensible Einträge (Codes, Passwörter) verfallen automatisch
    var expiresAt: Date?
    /// Per Texterkennung gefundener Text in Bildern (durchsuchbar)
    var ocrText: String?
    var ocrDone: Bool?
    /// Linkvorschau
    var linkTitle: String?
    var linkImageFile: String?
    var linkDone: Bool?

    /// Angepinnt = dauerhaft: Notiz oder in mindestens einer Pinnwand
    var isKept: Bool { isNote || !pinboardIds.isEmpty }
}

struct Pinboard: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var colorHex: String
    var createdAt: Date
}

struct Settings: Codable, Equatable {
    var autoCapture = true
    var historyLimit = 500
}

/// Gesamter Datenbestand. Alle Regeln als reine Funktionen → testbar.
struct Library: Codable, Equatable {
    var clips: [Clip] = []
    var pinboards: [Pinboard] = []
    var settings = Settings()
    /// Letzter gesehener UIPasteboard.changeCount (geteilt zwischen App und Tastatur)
    var lastChangeCount: Int = -1
    /// Wann die Tastatur zuletzt mit vollem Zugriff lief (Status für die Einrichtungsseite)
    var keyboardSeen: Date?
    /// Zeitpunkt der letzten Änderung – entscheidet, welche Kopie (Datei oder Spiegel) aktueller ist
    var modifiedAt: Date?
    /// Neue Bildschirmfotos automatisch übernehmen (optional, damit alte Daten weiter dekodierbar sind)
    var importScreenshots: Bool?
    var lastScreenshotAt: Date?
    /// Tracking-Parameter aus Links entfernen (nil = an)
    var cleanLinks: Bool?
    /// Codes/Passwörter nach 10 Minuten löschen (nil = an)
    var autoDeleteSensitive: Bool?
    /// Titel und Bild von Links laden (nil = an)
    var fetchLinkPreviews: Bool?

    static let sensitiveLifetime: TimeInterval = 600

    struct NewClip {
        var kind: ClipKind
        var text: String? = nil
        var imageFile: String? = nil
        var thumbFile: String? = nil
        var imageWidth: Double? = nil
        var imageHeight: Double? = nil
        var fileName: String? = nil
        var hash: String
        var isNote = false
        var expiresAt: Date? = nil
    }

    /// Baut einen Text-Eintrag nach den Einstellungen: Links säubern, Sensibles markieren.
    func textClip(_ raw: String, concealed: Bool = false, now: Date = Date()) -> NewClip {
        var text = raw
        let kind = Detect.kind(text)
        if kind == .link, cleanLinks != false { text = Detect.cleanLink(text) }
        let sensitive = autoDeleteSensitive != false && (concealed || Detect.isSensitive(text))
        return NewClip(kind: kind, text: text, hash: Detect.hash(text),
                       expiresAt: sensitive ? now.addingTimeInterval(Library.sensitiveLifetime) : nil)
    }

    /// Entfernt abgelaufene, nicht angepinnte Einträge
    mutating func purgeExpired(now: Date = Date()) {
        clips.removeAll { c in !c.isKept && (c.expiresAt.map { $0 <= now } ?? false) }
    }

    /// Fügt hinzu oder holt Dublette nach oben. Liefert (id, istNeu).
    @discardableResult
    mutating func add(_ n: NewClip, now: Date = Date(), id: String = Library.newId()) -> (String, Bool) {
        if let i = clips.firstIndex(where: { $0.hash == n.hash }) {
            var c = clips.remove(at: i)
            c.usedAt = now
            if n.isNote { c.isNote = true }
            if let e = n.expiresAt { c.expiresAt = e }
            clips.insert(c, at: 0)
            return (c.id, false)
        }
        let c = Clip(id: id, kind: n.kind, text: n.text, imageFile: n.imageFile, thumbFile: n.thumbFile,
                     imageWidth: n.imageWidth, imageHeight: n.imageHeight, fileName: n.fileName, hash: n.hash,
                     createdAt: now, usedAt: now, pinboardIds: [], isNote: n.isNote, expiresAt: n.expiresAt)
        clips.insert(c, at: 0)
        applyLimit()
        return (id, true)
    }

    /// Kürzt nur nicht angepinnte Einträge auf das Limit (Liste ist nach usedAt absteigend).
    mutating func applyLimit() {
        var loose = 0
        clips = clips.filter { c in
            if c.isKept { return true }
            loose += 1
            return loose <= settings.historyLimit
        }
    }

    mutating func touch(_ id: String, now: Date = Date()) {
        guard let i = clips.firstIndex(where: { $0.id == id }) else { return }
        var c = clips.remove(at: i)
        c.usedAt = now
        clips.insert(c, at: 0)
    }

    mutating func update(_ id: String, _ f: (inout Clip) -> Void) {
        guard let i = clips.firstIndex(where: { $0.id == id }) else { return }
        f(&clips[i])
    }

    mutating func editText(_ id: String, _ text: String) {
        update(id) {
            $0.text = text
            $0.kind = Detect.kind(text)
            $0.hash = Detect.hash(text)
            $0.linkDone = nil
            $0.linkTitle = nil
            $0.linkImageFile = nil
        }
    }

    mutating func togglePin(_ clipId: String, _ boardId: String) {
        update(clipId) { c in
            if let i = c.pinboardIds.firstIndex(of: boardId) { c.pinboardIds.remove(at: i) } else { c.pinboardIds.append(boardId) }
        }
        applyLimit()
    }

    mutating func delete(_ id: String) { clips.removeAll { $0.id == id } }

    mutating func clearHistory() { clips.removeAll { !$0.isKept } }

    mutating func deletePinboard(_ id: String) {
        pinboards.removeAll { $0.id == id }
        for i in clips.indices { clips[i].pinboardIds.removeAll { $0 == id } }
        applyLimit()
    }

    func filtered(query: String = "", kind: ClipKind? = nil, pinboard: String? = nil, keptOnly: Bool = false,
                  now: Date = Date()) -> [Clip] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return clips.filter { c in
            (c.isKept || (c.expiresAt.map { $0 > now } ?? true))
                && (kind == nil || c.kind == kind)
                && (pinboard == nil || c.pinboardIds.contains(pinboard!))
                && (!keptOnly || c.isKept)
                && (q.isEmpty || (c.text ?? "").lowercased().contains(q) || (c.title ?? "").lowercased().contains(q)
                    || (c.fileName ?? "").lowercased().contains(q) || (c.ocrText ?? "").lowercased().contains(q)
                    || (c.linkTitle ?? "").lowercased().contains(q))
        }
    }

    /// Bild-/Vorschaudateien, die kein Eintrag mehr nutzt
    func referencedFiles() -> Set<String> {
        Set(clips.flatMap { [$0.imageFile, $0.thumbFile, $0.linkImageFile].compactMap { $0 } })
    }

    static func newId() -> String { UUID().uuidString.lowercased() }
}
