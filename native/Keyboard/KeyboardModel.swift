import SwiftUI
import UIKit

/// Zustand der Tastatur-Oberfläche
final class KeyboardModel: ObservableObject {
    struct Actions {
        var insert: (String) -> Void = { _ in }
        var deleteBackward: () -> Void = {}
        var nextKeyboard: () -> Void = {}
        /// negative Werte = Cursor nach links
        var moveCursor: (Int) -> Void = { _ in }
        var readClipboard: () -> String? = { nil }
    }

    var actions = Actions()
    @Published var store: SharedStore?
    @Published var hasFullAccess = true
    @Published var showGlobe = true
    @Published var dark = false
    @Published var toast: String?
    /// Suche über die eingebaute Mini-Tastatur
    @Published var searching = false
    @Published var query = ""
    /// Eintrag, für den die Aktionsleiste offen ist (langes Drücken)
    @Published var actionClip: Clip?
    private var toastWork: DispatchWorkItem?

    func reset() {
        searching = false
        query = ""
        actionClip = nil
    }

    func flash(_ text: LocalizedStringResource) {
        toast = String(localized: text)
        toastWork?.cancel()
        let w = DispatchWorkItem { [weak self] in self?.toast = nil }
        toastWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: w)
    }

    /// Antippen: Text einsetzen (mit Platzhaltern), Bilder/Dateien in die Zwischenablage legen
    func use(_ clip: Clip, transform: Transform? = nil) {
        guard let store else { return }
        switch clip.kind {
        case .image, .file:
            Pasteboard.write(clip, store: store)
            flash(clip.kind == .image ? "Bild kopiert – im Feld halten → Einsetzen" : "Datei kopiert – im Feld halten → Einsetzen")
        default:
            var text = clip.text ?? ""
            if let transform { text = transform.apply(text) }
            let clipboard = Templates.needsClipboard(text) ? actions.readClipboard() : nil
            let (out, back) = Templates.expand(text, clipboard: clipboard)
            actions.insert(out)
            if let back, back > 0 { actions.moveCursor(-back) }
            store.mutate { $0.touch(clip.id) }
        }
        if searching { searching = false; query = "" }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func insertAndPin(_ clip: Clip) {
        use(clip)
        store?.mutate { lib in lib.update(clip.id) { $0.isNote = true } }
        flash("Eingefügt und angepinnt")
    }
}
