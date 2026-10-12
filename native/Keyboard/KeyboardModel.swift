import SwiftUI
import UIKit

/// Zustand der Tastatur-Oberfläche
final class KeyboardModel: ObservableObject {
    struct Actions {
        var insert: (String) -> Void = { _ in }
        var deleteBackward: () -> Void = {}
        var nextKeyboard: () -> Void = {}
    }

    var actions = Actions()
    @Published var store: SharedStore?
    @Published var hasFullAccess = true
    @Published var showGlobe = true
    @Published var toast: String?
    private var toastWork: DispatchWorkItem?

    func flash(_ text: LocalizedStringResource) {
        toast = String(localized: text)
        toastWork?.cancel()
        let w = DispatchWorkItem { [weak self] in self?.toast = nil }
        toastWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: w)
    }

    func use(_ clip: Clip) {
        guard let store else { return }
        switch clip.kind {
        case .image, .file:
            Pasteboard.write(clip, store: store)
            flash(clip.kind == .image ? "Bild kopiert – im Feld halten → Einsetzen" : "Datei kopiert – im Feld halten → Einsetzen")
        default:
            actions.insert(clip.text ?? "")
            store.mutate { $0.touch(clip.id) }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
