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
                    StatusRow(ok: store.isShared, title: "Gemeinsamer Speicher",
                              hint: store.isShared ? "App und Tastatur teilen ihre Daten." : "App Group fehlt – mit SideStore/AltStore installieren.")
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

                Section("Kurzbefehl (optional)") {
                    Text("Kurzbefehle → „Zwischenablage abrufen“ → „URL codieren“ → Text „ablage://add?text=“ + Ergebnis → „URLs öffnen“. Mit Bedienungshilfen → Tippen → Auf Rückseite tippen auf Doppeltippen legen.")
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
