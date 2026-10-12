import Photos
import UIKit

/// Übernimmt neue Bildschirmfotos aus der Fotomediathek in den Verlauf.
/// Läuft in der App (beim Öffnen) und in der Tastatur (beim Erscheinen), sofern Fotozugriff erteilt ist.
enum Screenshots {
    static var authorized: Bool {
        let s = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return s == .authorized || s == .limited
    }

    /// Nur in der App aufrufen – Erweiterungen dürfen keinen Berechtigungsdialog zeigen.
    static func requestAccess(_ done: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in
            DispatchQueue.main.async { done(s == .authorized || s == .limited) }
        }
    }

    /// Importiert höchstens `limit` Bildschirmfotos, die nach dem letzten Import entstanden sind.
    @discardableResult
    static func importNew(into store: SharedStore, limit: Int = 5) -> Int {
        guard store.library.importScreenshots == true, authorized else { return 0 }
        let since = store.library.lastScreenshotAt ?? Date().addingTimeInterval(-3600)
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "(mediaSubtypes & %d) != 0 AND creationDate > %@",
                                     PHAssetMediaSubtype.photoScreenshot.rawValue, since as NSDate)
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        opts.fetchLimit = limit
        let assets = PHAsset.fetchAssets(with: .image, options: opts)
        guard assets.count > 0 else { return 0 }

        let req = PHImageRequestOptions()
        req.isSynchronous = true
        req.isNetworkAccessAllowed = false
        req.deliveryMode = .highQualityFormat
        var added = 0
        var newest = since
        assets.enumerateObjects { asset, _, _ in
            autoreleasepool {
                PHImageManager.default().requestImageDataAndOrientation(for: asset, options: req) { data, uti, _, _ in
                    guard let data else { return }
                    let ext = (uti ?? "").contains("png") ? "png" : (uti ?? "").contains("heic") ? "heic" : "jpg"
                    if let n = store.saveImage(data, ext: ext) {
                        let (_, isNew) = store.mutate { $0.add(n, now: asset.creationDate ?? Date()) }
                        if isNew { added += 1 }
                    }
                }
                if let d = asset.creationDate, d > newest { newest = d }
            }
        }
        store.mutate { $0.lastScreenshotAt = newest }
        return added
    }
}
