import SwiftUI
import UniformTypeIdentifiers

/// Sicherung des gesamten Bestands als eine JSON-Datei inkl. Bilder (Base64).
/// Wichtig wegen der 7-Tage-Signatur: Neuinstallation ohne Datenverlust.
struct BackupFile: Codable {
    var version = 1
    var createdAt = Date()
    var library: Library
    var files: [String: Data]
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let d = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        data = d
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

enum Backup {
    static func export(_ store: SharedStore) throws -> BackupDocument {
        var files: [String: Data] = [:]
        for name in store.library.referencedFiles() {
            if let url = store.url(for: name), let d = try? Data(contentsOf: url) { files[name] = d }
        }
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .secondsSince1970
        return BackupDocument(data: try enc.encode(BackupFile(library: store.library, files: files)))
    }

    static var fileName: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "Ablage-Backup-\(f.string(from: Date()))"
    }

    /// Führt zusammen: unbekannte Einträge (nach Fingerabdruck) und Pinnwände kommen dazu, Vorhandenes bleibt.
    /// Liefert die Zahl neuer Einträge.
    static func restore(from url: URL, into store: SharedStore) throws -> Int {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .secondsSince1970
        let backup = try dec.decode(BackupFile.self, from: Data(contentsOf: url))
        for (name, data) in backup.files { store.saveData(data, name: name) }
        return store.mutate { lib in
            var added = 0
            for p in backup.library.pinboards where !lib.pinboards.contains(where: { $0.id == p.id }) { lib.pinboards.append(p) }
            let known = Set(lib.clips.map(\.hash))
            for c in backup.library.clips where !known.contains(c.hash) {
                lib.clips.append(c)
                added += 1
            }
            lib.clips.sort { $0.usedAt > $1.usedAt }
            return added
        }
    }
}
