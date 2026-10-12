import LinkPresentation
import UIKit
import Vision

/// Ergänzt Einträge im Hintergrund der App: Texterkennung in Bildern und Linkvorschau.
/// Läuft nur in der App (nicht in der Tastatur – dort ist Speicher knapp).
@MainActor
enum Enrichment {
    private static var running = false

    static func run(_ store: SharedStore) {
        guard !running else { return }
        running = true
        Task {
            await recognizeText(store)
            if store.library.fetchLinkPreviews != false { await loadLinkPreviews(store) }
            running = false
        }
    }

    // MARK: Texterkennung (OCR)

    private static func recognizeText(_ store: SharedStore) async {
        let todo = store.library.clips.filter { $0.kind == .image && $0.ocrDone != true }.prefix(10)
        for clip in todo {
            guard let url = store.url(for: clip.imageFile) else { continue }
            let text = await Task.detached(priority: .utility) { ocr(url) }.value
            store.mutate { lib in
                lib.update(clip.id) {
                    $0.ocrText = text
                    $0.ocrDone = true
                }
            }
        }
    }

    nonisolated static func ocr(_ url: URL) -> String? {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["de-DE", "en-US"]
        let handler = VNImageRequestHandler(url: url)
        guard (try? handler.perform([request])) != nil else { return nil }
        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    // MARK: Linkvorschau

    private static func loadLinkPreviews(_ store: SharedStore) async {
        let todo = store.library.clips.filter { $0.kind == .link && $0.linkDone != true }.prefix(10)
        for clip in todo {
            guard let url = Detect.url(clip.text ?? "") else { continue }
            let provider = LPMetadataProvider()
            provider.timeout = 8
            let meta = try? await provider.startFetchingMetadata(for: url)
            var imageFile: String?
            if let item = meta?.imageProvider, let image = await loadImage(item),
               let jpg = image.preparingThumbnail(of: CGSize(width: 600, height: 600 * image.size.height / max(image.size.width, 1)))?
                .jpegData(compressionQuality: 0.7) {
                let name = "\(clip.id)-link.jpg"
                if store.saveData(jpg, name: name) { imageFile = name }
            }
            store.mutate { lib in
                lib.update(clip.id) {
                    $0.linkTitle = meta?.title
                    $0.linkImageFile = imageFile
                    $0.linkDone = true
                }
            }
        }
    }

    private static func loadImage(_ provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { cont in
            provider.loadObject(ofClass: UIImage.self) { obj, _ in cont.resume(returning: obj as? UIImage) }
        }
    }
}
