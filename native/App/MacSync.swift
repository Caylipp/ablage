import Foundation

/// Abgleich mit dem Mac über einen Ordner in iCloud Drive (ohne eigenen iCloud-Account der App):
/// - schreibt `verlauf.json` (Text-Einträge, neueste zuerst) – der Mac liest sie, z. B. per Raycast
/// - liest `an-iphone.txt` (eine Zeile = ein Eintrag, vom Mac angehängt), übernimmt sie und leert die Datei
enum MacSync {
    private static let bookmarkKey = "macSyncFolderBookmark"
    static let exportName = "verlauf.json"
    static let inboxName = "an-iphone.txt"

    struct Entry: Codable {
        var id: String
        var kind: String
        var text: String
        var title: String?
        var pinned: Bool
        var date: Date
    }

    static var folderName: String? { resolveFolder()?.lastPathComponent }

    static func setFolder(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        if let data = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        }
    }

    static func clearFolder() { UserDefaults.standard.removeObject(forKey: bookmarkKey) }

    private static func resolveFolder() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale) else { return nil }
        if stale, let fresh = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(fresh, forKey: bookmarkKey)
        }
        return url
    }

    /// Liefert die Zahl der vom Mac übernommenen Einträge; nil = kein Ordner gewählt / kein Zugriff
    @discardableResult
    static func sync(_ store: SharedStore) -> Int? {
        guard let folder = resolveFolder(), folder.startAccessingSecurityScopedResource() else { return nil }
        defer { folder.stopAccessingSecurityScopedResource() }
        let coordinator = NSFileCoordinator()
        var err: NSError?

        // 1. Eingang vom Mac übernehmen
        var imported = 0
        let inbox = folder.appendingPathComponent(inboxName)
        coordinator.coordinate(writingItemAt: inbox, options: .forMerging, error: &err) { url in
            guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return }
            let lines = raw.components(separatedBy: "\n").map { $0.replacingOccurrences(of: "\\n", with: "\n") }
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            guard !lines.isEmpty else { return }
            store.mutate { lib in
                for l in lines {
                    if lib.add(lib.textClip(l)).1 { imported += 1 }
                }
            }
            try? "".write(to: url, atomically: true, encoding: .utf8)
        }

        // 2. Verlauf für den Mac schreiben
        let entries = store.library.filtered().compactMap { c -> Entry? in
            guard let text = c.text ?? c.ocrText else { return nil }
            return Entry(id: c.id, kind: c.kind.rawValue, text: text, title: c.title ?? c.linkTitle, pinned: c.isKept, date: c.usedAt)
        }
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(entries) {
            coordinator.coordinate(writingItemAt: folder.appendingPathComponent(exportName), options: .forReplacing, error: &err) { url in
                try? data.write(to: url, options: .atomic)
            }
        }
        return imported
    }
}
