import AppIntents
import UniformTypeIdentifiers

/// Kurzbefehle-Aktion „In Ablage sichern“: läuft im Hintergrund, öffnet die App nicht und zeigt
/// keinen Einsetzen-Dialog (die Zwischenablage liest der Kurzbefehl selbst). Ideal mit „Auf Rückseite tippen“.
struct SaveToAblageIntent: AppIntent {
    static var title: LocalizedStringResource = "In Ablage sichern"
    static var description = IntentDescription("Sichert Text, Bild oder Datei im Ablage-Verlauf, ohne die App zu öffnen.")
    static var openAppWhenRun = false

    @Parameter(title: "Inhalt", supportedContentTypes: [.item])
    var content: IntentFile?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let content else { return .result(dialog: "Nichts übergeben") }
        let store = SharedStore()
        let data = content.data
        let type = content.type ?? UTType(filenameExtension: (content.filename as NSString).pathExtension) ?? .data
        let new: Library.NewClip?
        if type.conforms(to: .text), let s = String(data: data, encoding: .utf8),
           !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            new = .init(kind: Detect.kind(s), text: s, hash: Detect.hash(s))
        } else if type.conforms(to: .image) {
            new = store.saveImage(data, ext: type.preferredFilenameExtension ?? "png")
        } else {
            new = store.saveFile(data, type: type)
        }
        guard let new else { return .result(dialog: "Konnte nicht gesichert werden") }
        let (_, isNew) = store.mutate { $0.add(new) }
        return .result(dialog: isNew ? "In Ablage gesichert" : "Schon in Ablage – nach oben geholt")
    }
}

struct AblageShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SaveToAblageIntent(), phrases: ["In \(.applicationName) sichern"],
                    shortTitle: "In Ablage sichern", systemImageName: "doc.on.clipboard")
    }
}
