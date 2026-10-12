import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: SharedStore
    @EnvironmentObject var toast: Toast
    @State private var confirmClear = false
    @State private var testInput = ""
    @State private var pickFolder = false
    @State private var exportDoc: BackupDocument?
    @State private var showExport = false
    @State private var importBackup = false
    @State private var macFolder = MacSync.folderName

    private var keyboardAdded: Bool {
        UITextInputMode.activeInputModes.contains {
            (($0.value(forKey: "identifier") as? String) ?? "").contains("com.philipphoang.ablage")
        }
    }

    private func open(_ s: String) {
        if let url = URL(string: s) { UIApplication.shared.open(url) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section { ShortcutHero(openShortcuts: { open("shortcuts://") }) }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                Section {
                    StatusRow(ok: keyboardAdded, title: "Tastatur hinzugefügt",
                              hint: "Einstellungen → Allgemein → Tastatur → Tastaturen → Tastatur hinzufügen → **Ablage**")
                    StatusRow(ok: store.library.keyboardSeen != nil, title: "Voller Zugriff aktiv",
                              hint: store.library.keyboardSeen.map { "Tastatur zuletzt aktiv: \(Detect.relative($0))" }
                                ?? "Unter Tastaturen auf **Ablage** tippen und **Vollen Zugriff erlauben** einschalten. Danach die Tastatur einmal öffnen.")
                    StatusRow(ok: store.isShared || store.library.keyboardSeen != nil, title: "App und Tastatur verbunden",
                              hint: store.isShared ? "Über die App Group."
                                  : store.library.keyboardSeen != nil ? "Über den Ersatzweg (private Zwischenablage)."
                                  : "Öffne die Tastatur einmal, dann verbindet sie sich.")
                } header: {
                    Text("Tastatur")
                } footer: {
                    Text("Kopiere etwas, tippe in ein Textfeld, halte die Weltkugel und wähle **Ablage**. Die Tastatur sichert die Zwischenablage und zeigt deinen Verlauf. Antippen fügt ein.")
                }

                Section {
                    StatusRow(ok: nil, title: "Einsetzen immer erlauben",
                              hint: "In den iPhone-Einstellungen bei Ablage: **Einsetzen aus anderen Apps** auf **Erlauben** stellen, nicht auf Fragen. Dann kommt kein Dialog mehr.")
                    Button { open(UIApplication.openSettingsURLString) } label: {
                        Label("Ablage-Einstellungen öffnen", systemImage: "arrow.up.forward.app")
                    }
                } header: {
                    Text("Ohne Nachfrage")
                }

                Section {
                    HStack {
                        Text(sampleText).font(.callout)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = String(localized: sampleText)
                            toast.show("Beispieltext kopiert")
                        } label: { Label("Kopieren", systemImage: "doc.on.doc").labelStyle(.iconOnly) }
                            .buttonStyle(.bordered)
                    }
                    TextField("Hier einfügen – mit der Ablage-Tastatur", text: $testInput, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Testen")
                } footer: {
                    Text("1. Beispieltext kopieren. 2. Ins Feld tippen und zur Ablage-Tastatur wechseln. 3. Die Karte antippen – erscheint der Text im Feld, funktioniert alles.")
                }

                Section {
                    Toggle("Beim Öffnen der App einfügen", isOn: Binding(
                        get: { store.library.settings.autoCapture },
                        set: { v in store.mutate { $0.settings.autoCapture = v } }))
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
                    Toggle("Links von Tracking säubern", isOn: flag(\.cleanLinks))
                    Toggle("Codes und Passwörter nach 10 Min. löschen", isOn: flag(\.autoDeleteSensitive))
                    Toggle("Linkvorschau laden", isOn: flag(\.fetchLinkPreviews))
                    Picker("Verlauf behalten", selection: Binding(
                        get: { store.library.settings.historyLimit },
                        set: { v in store.mutate { $0.settings.historyLimit = v; $0.applyLimit() } })) {
                        ForEach([100, 500, 1000, 5000], id: \.self) { Text(verbatim: "\($0)").tag($0) }
                    }
                    Button("Verlauf leeren", role: .destructive) { confirmClear = true }
                } header: {
                    Text("Optionen")
                } footer: {
                    let kept = store.library.clips.filter(\.isKept).count
                    Text("\(store.library.clips.count) Einträge, davon \(kept) angepinnt. Angepinntes zählt nicht zum Limit und bleibt beim Leeren erhalten. Neue Bildschirmfotos landen beim nächsten Öffnen von App oder Tastatur im Verlauf. Die Linkvorschau lädt Titel und Bild direkt von der verlinkten Seite.")
                }

                Section {
                    if let macFolder {
                        LabeledContent("Ordner", value: macFolder)
                        Button { syncNow() } label: { Label("Jetzt abgleichen", systemImage: "arrow.triangle.2.circlepath") }
                        Button("Ordner entfernen", role: .destructive) { MacSync.clearFolder(); self.macFolder = nil }
                    } else {
                        Button { pickFolder = true } label: { Label("Ordner in iCloud Drive wählen", systemImage: "folder.badge.plus") }
                    }
                } header: {
                    Text("Mac-Sync")
                } footer: {
                    Text("Lege in iCloud Drive einen Ordner **Ablage** an und wähle ihn hier. Ablage schreibt dort deinen Verlauf als verlauf.json und übernimmt Zeilen aus an-iphone.txt. Auf dem Mac lesen die Raycast-Skripte aus dem Projektordner mac/raycast diese Dateien. Abgeglichen wird beim Öffnen der App und bei jedem Sichern per Kurzbefehl.")
                }

                Section {
                    Button {
                        if let doc = try? Backup.export(store) { exportDoc = doc; showExport = true }
                    } label: { Label("Backup exportieren", systemImage: "square.and.arrow.up") }
                    Button { importBackup = true } label: { Label("Backup importieren", systemImage: "square.and.arrow.down") }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Eine Datei mit allen Einträgen, Pinnwänden und Bildern. Beim Import kommt nur dazu, was noch fehlt. Tipp: vor dem Neuinstallieren exportieren.")
                }

                Section {
                    Text("Alle Daten bleiben auf diesem iPhone. Ablage 3.0").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einrichtung")
            .fileImporter(isPresented: $pickFolder, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result {
                    MacSync.setFolder(url)
                    macFolder = MacSync.folderName
                    syncNow()
                }
            }
            .fileExporter(isPresented: $showExport, document: exportDoc, contentType: .json, defaultFilename: Backup.fileName) { result in
                if case .success = result { toast.show("Backup gespeichert") }
            }
            .fileImporter(isPresented: $importBackup, allowedContentTypes: [.json]) { result in
                guard case .success(let url) = result else { return }
                do {
                    let n = try Backup.restore(from: url, into: store)
                    toast.show("\(n) Einträge wiederhergestellt")
                } catch {
                    toast.show("Backup konnte nicht gelesen werden")
                }
            }
            .confirmationDialog("Verlauf leeren?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Leeren", role: .destructive) {
                    store.mutate { $0.clearHistory() }
                    toast.show("Verlauf geleert")
                }
            } message: { Text("Angepinnte Einträge bleiben erhalten.") }
        }
    }

    private func syncNow() {
        if let n = MacSync.sync(store) { toast.show("Abgeglichen – \(n) neu vom Mac") } else { toast.show("Kein Zugriff auf den Ordner") }
    }

    /// Schalter für optionale Bool-Einstellungen, bei denen nil „an“ bedeutet
    private func flag(_ key: WritableKeyPath<Library, Bool?>) -> Binding<Bool> {
        Binding(get: { store.library[keyPath: key] != false }, set: { v in store.mutate { $0[keyPath: key] = v } })
    }

    private var sampleText: LocalizedStringResource { "Hallo aus Ablage! Dieser Text kommt aus deinem Verlauf." }
}

/// Hervorgehobene Karte: der empfohlene Weg, ohne App und ohne Dialog zu sichern.
private struct ShortcutHero: View {
    let openShortcuts: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .font(.title2).foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Empfohlen").font(.caption.weight(.bold)).textCase(.uppercase).opacity(0.85)
                    Text("Kopieren, zweimal hinten tippen – gesichert").font(.headline)
                }
            }
            Text("Ohne die App zu öffnen und ohne Nachfrage. Einmal einrichten, dann funktioniert es überall.")
                .font(.subheadline).opacity(0.9)

            VStack(alignment: .leading, spacing: 10) {
                Step(n: 1, text: "In **Kurzbefehle** einen neuen Kurzbefehl anlegen.")
                Step(n: 2, text: "Aktion **Zwischenablage abrufen** hinzufügen.")
                Step(n: 3, text: "Nach **Ablage** suchen und **In Ablage sichern** hinzufügen. Als Inhalt die Zwischenablage wählen.")
                Step(n: 4, text: "Einstellungen → Bedienungshilfen → Tippen → **Auf Rückseite tippen** → Doppeltippen → deinen Kurzbefehl.")
            }

            Button(action: openShortcuts) {
                Label("Kurzbefehle öffnen", systemImage: "arrow.up.forward.app")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(LinearGradient(colors: [Color(hex: "#3D7BFD"), Color(hex: "#9B5CF6")], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct Step: View {
    let n: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(verbatim: "\(n)").font(.caption.weight(.bold))
                .frame(width: 22, height: 22).background(.white.opacity(0.25), in: Circle())
            Text(text).font(.subheadline)
        }
    }
}

private struct StatusRow: View {
    /// nil = Hinweis ohne prüfbaren Status
    let ok: Bool?
    let title: LocalizedStringKey
    let hint: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: ok == nil ? "hand.raised.circle.fill" : ok! ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(ok == nil ? Color.accentColor : ok! ? .green : .orange).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(hint).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
