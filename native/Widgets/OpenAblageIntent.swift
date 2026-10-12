import AppIntents

/// Öffnet Ablage – für den Steuerzentrale-Knopf. Beim Öffnen sichert die App die Zwischenablage automatisch.
struct OpenAblageIntent: AppIntent {
    static var title: LocalizedStringResource = "Ablage öffnen"
    static var description = IntentDescription("Öffnet Ablage; die Zwischenablage wird dabei gesichert.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult { .result() }
}
