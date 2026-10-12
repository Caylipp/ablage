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
            nextKeyboard: { [weak self] in self?.advanceToNextInputMode() }
        )
        let host = UIHostingController(rootView: KeyboardView(model: model))
        host.view.backgroundColor = .clear
        host.sizingOptions = []
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        let height = view.heightAnchor.constraint(equalToConstant: 290)
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
        if result == .added { model.flash("Zwischenablage gesichert") }
    }
}

