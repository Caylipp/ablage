import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: SharedStore
    @EnvironmentObject var toast: Toast
    @State private var confirmClear = false

    private var keyboardAdded: Bool {
        UITextInputMode.activeInputModes.contains {
            (($0.value(forKey: "identifier") as? String) ?? "").contains("com.philipphoang.ablage")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    StatusRow(ok: keyboardAdded, title: "Tastatur hinzugefügt",
                              hint: "Einstellungen → Allgemein → Tastatur → Tastaturen → Tastatur hinzufügen → Ablage")
                    StatusRow(ok: store.library.keyboardSeen != nil, title: "Voller Zugriff aktiv",
                              hint: store.library.keyboardSeen.map { "Tastatur zuletzt gesehen \(Detect.relative($0))" }
                                ?? "Dort auf „Ablage“ tippen → „Vollen Zugriff erlauben“. Danach die Tastatur einmal öffnen.")
                    StatusRow(ok: store.isShared || store.library.keyboardSeen != nil, title: "App und Tastatur verbunden",
                              hint: store.isShared ? "Über App Group."
                                  : store.library.keyboardSeen != nil ? "Über Ersatzweg (private Zwischenablage), weil das Sideload-Werkzeug keine App Group eingerichtet hat."
                                  : "Tastatur einmal öffnen, dann verbindet sie sich.")
                    Button("iPhone-Einstellungen öffnen") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                } header: {
                    Text("Einrichtung")
                } footer: {
                    Text("So nutzt du Ablage: Kopiere irgendwo etwas. Tippe in ein Textfeld, halte den Globus und wähle „Ablage“. Die Tastatur sichert die Zwischenablage automatisch und zeigt deinen Verlauf. Antippen fügt ein.")
                }

                Section {
                    Toggle("Beim Öffnen der App einfügen", isOn: Binding(
                        get: { store.library.settings.autoCapture },
                        set: { v in store.mutate { $0.settings.autoCapture = v } }))
                } footer: {
                    Text("Damit die App nicht jedes Mal „Einsetzen erlauben?“ fragt: Einstellungen → Apps → Ablage → Aus anderen Apps einsetzen → Erlauben.")
                }

                Section {
                    Toggle("Bildschirmfotos übernehmen", isOn: Binding(
                        get: { store.library.importScreenshots == true },
                        set: { v in
                            guard v else { store.mutate { $0.importScreenshots = false }; return }
                            Screenshots.requestAccess { ok in
                                store.mutate {
                                    $0.importScreenshots = ok
                                    $0.lastScreenshotAt = Date().addingTimeInterval(-3600)
                                }
                                if ok { Screenshots.importNew(into: store) } else { toast.show("Fotozugriff verweigert") }
                            }
                        }))
                } footer: {
                    Text("Neue Bildschirmfotos landen automatisch im Verlauf – beim Öffnen der App oder der Tastatur.")
                }

                Section {
                    Picker("Verlauf behalten", selection: Binding(
                        get: { store.library.settings.historyLimit },
                        set: { v in store.mutate { $0.settings.historyLimit = v; $0.applyLimit() } })) {
                        ForEach([100, 500, 1000, 5000], id: \.self) { Text("\($0)").tag($0) }
                    }
                    Button("Verlauf leeren", role: .destructive) { confirmClear = true }
                } footer: {
                    let kept = store.library.clips.filter(\.isKept).count
                    Text("\(store.library.clips.count) Einträge, davon \(kept) angepinnt. Angepinntes zählt nicht zum Limit und bleibt beim Leeren erhalten.")
                }

                Section("Sichern ohne App und ohne Nachfrage") {
                    Text("1. App Kurzbefehle → + → Aktion „Zwischenablage abrufen“.\n2. Aktion „In Ablage sichern“ (von Ablage), als Inhalt die Zwischenablage.\n3. Einstellungen → Bedienungshilfen → Tippen → Auf Rückseite tippen → Doppeltippen → diesen Kurzbefehl.\n\nDann: kopieren, zweimal hinten aufs iPhone tippen – gesichert, ohne Dialog.")
                        .font(.footnote)
                }

                Section {
                    Text("Alle Daten bleiben auf diesem iPhone. Ablage 2.0").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einrichtung")
            .confirmationDialog("Verlauf leeren?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Leeren", role: .destructive) {
                    store.mutate { $0.clearHistory() }
                    toast.show("Verlauf geleert")
                }
            } message: { Text("Angepinnte Einträge bleiben erhalten.") }
        }
    }
}

private struct StatusRow: View {
    let ok: Bool
    let title: String
    let hint: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: ok ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(ok ? .green : .orange).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(hint).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
