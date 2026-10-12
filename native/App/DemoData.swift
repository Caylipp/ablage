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
                         "max@beispiel.de", "https://www.spiegel.de/artikel", "Treffen um 15 Uhr im Café am Markt"]
            for (i, s) in texts.enumerated() {
                lib.add(.init(kind: Detect.kind(s), text: s, hash: Detect.hash(s)), now: Date().addingTimeInterval(Double(-600 * (texts.count - i))))
            }
            let (n, _) = lib.add(.init(kind: .text, text: "IBAN-Vorlage: DE00 0000 0000 0000 0000 00", hash: Detect.hash("iban"), isNote: true))
            lib.update(n) { $0.title = "Bankdaten-Vorlage"; $0.pinboardIds = ["privat"] }
            if let id = lib.clips.first(where: { $0.kind == .email })?.id { lib.togglePin(id, "arbeit") }
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
                .frame(height: 290)
                .background(Color(uiColor: .systemGray5))
        }
        .onAppear {
            DemoData.seed(store)
            model.store = store
            model.actions = .init(insert: { typed += $0 }, deleteBackward: { if !typed.isEmpty { typed.removeLast() } }, nextKeyboard: {})
        }
    }
}
#endif
