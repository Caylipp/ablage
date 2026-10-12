import UIKit

/// Ersatz für die App Group, wenn das Sideload-Werkzeug keine eingerichtet hat:
/// benannte (private) Zwischenablagen. iOS teilt sie zwischen App und Erweiterung desselben Teams,
/// ohne Sonder-Berechtigung und ohne „Einsetzen erlauben?“-Dialog. Die allgemeine Zwischenablage bleibt unberührt.
enum Mirror {
    private static let type = "public.data"
    private static let libraryName = UIPasteboard.Name("com.philipphoang.ablage.library")

    private static func board(_ name: UIPasteboard.Name, create: Bool) -> UIPasteboard? {
        UIPasteboard(name: name, create: create)
    }

    private static func fileBoard(_ file: String) -> UIPasteboard.Name {
        UIPasteboard.Name("com.philipphoang.ablage.f.\(file)")
    }

    static func readLibrary() -> Data? {
        board(libraryName, create: false)?.data(forPasteboardType: type)
    }

    static func writeLibrary(_ data: Data) {
        board(libraryName, create: true)?.setData(data, forPasteboardType: type)
    }

    static func putFile(_ name: String, _ data: Data) {
        board(fileBoard(name), create: true)?.setData(data, forPasteboardType: type)
    }

    static func file(_ name: String) -> Data? {
        board(fileBoard(name), create: false)?.data(forPasteboardType: type)
    }

    static func removeFile(_ name: String) {
        UIPasteboard.remove(withName: fileBoard(name))
    }
}
