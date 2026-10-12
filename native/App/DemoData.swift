#if DEBUG
import SwiftUI

/// Nur für Debug-Builds: Beispieldaten und Tastatur-Vorschau für Screenshots im Simulator.
enum DemoData {
    static func seed(_ store: SharedStore) {
        guard store.library.clips.isEmpty else { return }
        store.mutate { lib in
            lib.pinboards = [Pinboard(id: "arbeit", name: "Arbeit", colorHex: "#3D7BFD", createdAt: Date()),
                             Pinboard(id: "privat", name: "Privat", colorHex: "#2FB36B", createdAt: Date())]
            let texts = ["Einkaufsliste: Milch, Brot, Kaffee", "func hello() {\n    print(\"Hallo\")\n}", "#9B5CF6",
                         "max@beispiel.de", "https://www.spiegel.de/artikel", "483920", "Treffen um 15 Uhr im Café am Markt"]
            for (i, s) in texts.enumerated() {
                lib.add(lib.textClip(s), now: Date().addingTimeInterval(Double(-120 * (texts.count - i))))
            }
            let (n, _) = lib.add(.init(kind: .text, text: "IBAN-Vorlage: DE00 0000 0000 0000 0000 00", hash: Detect.hash("iban"), isNote: true))
            lib.update(n) { $0.title = "Bankdaten-Vorlage"; $0.pinboardIds = ["privat"] }
            if let id = lib.clips.first(where: { $0.kind == .email })?.id { lib.togglePin(id, "arbeit") }
            if let id = lib.clips.first(where: { $0.kind == .link })?.id {
                lib.update(id) { $0.linkTitle = "Nachrichten, Hintergründe und Debatten"; $0.linkDone = true }
            }
        }
    }
}

struct KeyboardDemo: View {
    let store: SharedStore
    @StateObject private var model = KeyboardModel()
    @State private var typed = ""

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $typed).padding().overlay(alignment: .topLeading) {
                if typed.isEmpty { Text("Hier landet, was die Tastatur einfügt").foregroundStyle(.secondary).padding(22) }
            }
            KeyboardView(model: model)
                .frame(height: 300)
                .background(Color(uiColor: model.dark ? UIColor(white: 0.17, alpha: 1) : .systemGray5))
                .environment(\.colorScheme, model.dark ? .dark : .light)
        }
        .onAppear {
            DemoData.seed(store)
            model.store = store
            model.dark = ProcessInfo.processInfo.arguments.contains("-Dark")
            model.searching = ProcessInfo.processInfo.arguments.contains("-Search")
            if ProcessInfo.processInfo.arguments.contains("-Actions") { model.actionClip = store.library.clips.first { $0.kind == .text } }
            model.actions = .init(insert: { typed += $0 }, deleteBackward: { if !typed.isEmpty { typed.removeLast() } }, nextKeyboard: {})
        }
    }
}
#endif
