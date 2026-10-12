import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Gemeinsamer Datenspeicher für App und Tastatur im App-Group-Container.
/// Jede Änderung: koordiniert laden → ändern → atomar schreiben → Darwin-Notification an den anderen Prozess.
final class SharedStore: ObservableObject {
    static let defaultGroup = "group.com.philipphoang.ablage"
    static let changedNote = "com.philipphoang.ablage.changed" as CFString

    @Published private(set) var library = Library()
    /// false = keine App Group erreichbar (Tastatur ohne vollen Zugriff oder Signatur ohne Gruppe)
    let isShared: Bool
    let root: URL
    private var fileURL: URL { root.appendingPathComponent("library.json") }
    var imagesURL: URL { root.appendingPathComponent("images", isDirectory: true) }

    init() {
        let (url, shared) = SharedStore.locateContainer()
        root = url
        isShared = shared
        try? FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        reload()
        observeOtherProcess()
    }

    /// SideStore/AltStore benennen App Groups um und tragen die echten IDs in Info.plist → ALTAppGroups ein.
    /// In der Tastatur steht der Schlüssel evtl. nur in der Info.plist der Haupt-App (zwei Ordner höher).
    static func locateContainer() -> (URL, Bool) {
        var ids: [String] = []
        let bundles = [Bundle.main, Bundle(url: Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent())]
        for b in bundles.compactMap({ $0 }) {
            ids += (b.object(forInfoDictionaryKey: "ALTAppGroups") as? [String]) ?? []
        }
        ids.append(defaultGroup)
        for id in ids {
            if let u = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id),
               (try? FileManager.default.createDirectory(at: u.appendingPathComponent("Ablage"), withIntermediateDirectories: true)) != nil {
                return (u.appendingPathComponent("Ablage"), true)
            }
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Ablage")
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return (docs, false)
    }

    // MARK: Laden / Ändern

    func reload() {
        let lib = readFromDisk()
        if Thread.isMainThread { library = lib } else { DispatchQueue.main.async { self.library = lib } }
    }

    private func readFromDisk() -> Library {
        var result = Library()
        var err: NSError?
        NSFileCoordinator().coordinate(readingItemAt: fileURL, options: [], error: &err) { url in
            if let data = try? Data(contentsOf: url), let lib = try? Self.decoder.decode(Library.self, from: data) {
                result = lib
            }
        }
        return result
    }

    /// Ändert den Bestand prozess-sicher. Liefert den Rückgabewert der Änderung.
    @discardableResult
    func mutate<T>(_ change: (inout Library) -> T) -> T {
        var out: T!
        var lib = Library()
        var err: NSError?
        NSFileCoordinator().coordinate(writingItemAt: fileURL, options: .forMerging, error: &err) { url in
            if let data = try? Data(contentsOf: url), let saved = try? Self.decoder.decode(Library.self, from: data) {
                lib = saved
            }
            out = change(&lib)
            if let data = try? Self.encoder.encode(lib) { try? data.write(to: url, options: .atomic) }
        }
        if out == nil { out = change(&lib) } // Koordination fehlgeschlagen: trotzdem im Speicher anwenden
        let snapshot = lib
        if Thread.isMainThread { library = snapshot } else { DispatchQueue.main.async { self.library = snapshot } }
        removeOrphans(keep: snapshot.referencedFiles())
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(Self.changedNote), nil, nil, true)
        return out
    }

    private func observeOtherProcess() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let me = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(center, me, { _, observer, _, _, _ in
            guard let observer else { return }
            Unmanaged<SharedStore>.fromOpaque(observer).takeUnretainedValue().reload()
        }, Self.changedNote, nil, .deliverImmediately)
    }

    deinit {
        CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque())
    }

    private func removeOrphans(keep: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: imagesURL.path) else { return }
        for f in files where !keep.contains(f) {
            try? FileManager.default.removeItem(at: imagesURL.appendingPathComponent(f))
        }
    }

    // MARK: Dateien

    func url(for file: String?) -> URL? { file.map { imagesURL.appendingPathComponent($0) } }

    /// Speichert Bilddaten (PNG/JPEG …) ohne sie voll zu dekodieren – wichtig fürs 60-MB-Limit der Tastatur.
    func saveImage(_ data: Data, ext: String) -> Library.NewClip? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
        let w = (props?[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue
        let h = (props?[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue
        let id = Library.newId()
        let file = "\(id).\(ext)"
        let thumb = "\(id)-thumb.jpg"
        do { try data.write(to: imagesURL.appendingPathComponent(file)) } catch { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 360,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        if let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary),
           let jpg = UIImage(cgImage: cg).jpegData(compressionQuality: 0.75) {
            try? jpg.write(to: imagesURL.appendingPathComponent(thumb))
        }
        return .init(kind: .image, imageFile: file, thumbFile: thumb, imageWidth: w, imageHeight: h,
                     hash: Detect.hash(data, prefix: "i"))
    }

    func saveFile(_ data: Data, type: UTType) -> Library.NewClip? {
        let ext = type.preferredFilenameExtension ?? "bin"
        let file = "\(Library.newId()).\(ext)"
        do { try data.write(to: imagesURL.appendingPathComponent(file)) } catch { return nil }
        let name = "\(type.localizedDescription ?? "Datei") (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))"
        return .init(kind: .file, imageFile: file, fileName: name, hash: Detect.hash(data, prefix: "f"))
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()
}
