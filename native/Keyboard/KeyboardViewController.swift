import SwiftUI
import UIKit

/// Einstiegspunkt der Tastatur-Erweiterung. Hostet die SwiftUI-Oberfläche und reicht Aktionen an den textDocumentProxy.
final class KeyboardViewController: UIInputViewController {
    private var store: SharedStore?
    private let model = KeyboardModel()
    private var host: UIHostingController<KeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        model.actions = .init(
            insert: { [weak self] in self?.textDocumentProxy.insertText($0) },
            deleteBackward: { [weak self] in self?.textDocumentProxy.deleteBackward() },
            nextKeyboard: { [weak self] in self?.advanceToNextInputMode() },
            moveCursor: { [weak self] in self?.textDocumentProxy.adjustTextPosition(byCharacterOffset: $0) },
            readClipboard: { UIPasteboard.general.string }
        )
        let host = UIHostingController(rootView: KeyboardView(model: model))
        host.view.backgroundColor = .clear
        host.sizingOptions = []
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        let height = view.heightAnchor.constraint(equalToConstant: 300)
        height.priority = .defaultHigh
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            height,
        ])
        host.didMove(toParent: self)
        self.host = host
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyAppearance()
        model.reset()
        model.hasFullAccess = hasFullAccess
        model.showGlobe = needsInputModeSwitchKey
        guard hasFullAccess else { return }
        if store == nil { store = SharedStore() }
        guard let store else { return }
        model.store = store
        store.reload()
        store.mutate { $0.keyboardSeen = Date() }
        // Der Kern: was seit dem letzten Mal kopiert wurde, landet jetzt unsichtbar im Verlauf.
        let result = Pasteboard.capture(into: store)
        let shots = Screenshots.importNew(into: store, limit: 3)
        if result == .added { model.flash("Zwischenablage gesichert") } else if shots > 0 { model.flash("Bildschirmfoto übernommen") }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        applyAppearance()
    }

    /// Dunkel, wenn das Textfeld eine dunkle Tastatur wünscht oder das System dunkel ist
    private func applyAppearance() {
        let dark = textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark
        host?.overrideUserInterfaceStyle = dark ? .dark : .light
        model.dark = dark
    }
}
