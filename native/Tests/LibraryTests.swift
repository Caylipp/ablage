import XCTest

final class DetectTests: XCTestCase {
    func testKinds() {
        let cases: [(String, ClipKind)] = [
            ("#ff8800", .color), ("#FFF", .color), ("rgb(10, 20, 30)", .color),
            ("max@beispiel.de", .email), ("https://example.com/a?b=1", .link), ("www.spiegel.de", .link),
            ("github.com/expo/expo", .link), ("+49 170 1234567", .phone),
            ("const a = 1;\nreturn a;", .code), ("func f() { return 1; }", .code),
            ("Hallo Welt, wie geht es?", .text), ("12", .text), ("", .text),
            ("schau mal\nhttps://x.de", .text),
        ]
        for (input, kind) in cases { XCTAssertEqual(Detect.kind(input), kind, input) }
    }

    func testDomainAndHash() {
        XCTAssertEqual(Detect.domain("https://www.spiegel.de/a/b"), "spiegel.de")
        XCTAssertEqual(Detect.hash("abc"), Detect.hash("abc"))
        XCTAssertNotEqual(Detect.hash("abc"), Detect.hash("abd"))
        XCTAssertNotEqual(Detect.hash(Data("abc".utf8), prefix: "t"), Detect.hash(Data("abc".utf8), prefix: "i"))
    }
}

final class LibraryTests: XCTestCase {
    private func t(_ s: String) -> Library.NewClip { .init(kind: Detect.kind(s), text: s, hash: Detect.hash(s)) }

    func testNewestFirstAndDedupe() {
        var lib = Library()
        lib.add(t("a"), now: Date(timeIntervalSince1970: 1))
        lib.add(t("b"), now: Date(timeIntervalSince1970: 2))
        let (_, isNew) = lib.add(t("a"), now: Date(timeIntervalSince1970: 3))
        XCTAssertFalse(isNew)
        XCTAssertEqual(lib.clips.map(\.text), ["a", "b"])
        XCTAssertEqual(lib.clips[0].usedAt, Date(timeIntervalSince1970: 3))
    }

    func testLimitSparesKept() {
        var lib = Library()
        lib.settings.historyLimit = 2
        let (old, _) = lib.add(t("alt"))
        lib.togglePin(old, "p")
        let (note, _) = lib.add(.init(kind: .text, text: "notiz", hash: Detect.hash("notiz"), isNote: true))
        lib.add(t("1")); lib.add(t("2")); lib.add(t("3"))
        XCTAssertEqual(Set(lib.clips.compactMap(\.text)), ["3", "2", "alt", "notiz"])
        XCTAssertTrue(lib.clips.contains { $0.id == note })
    }

    func testClearHistoryKeepsPinnedAndNotes() {
        var lib = Library()
        let (a, _) = lib.add(t("a"))
        lib.add(t("b"))
        lib.add(.init(kind: .text, text: "n", hash: Detect.hash("n"), isNote: true))
        lib.togglePin(a, "p")
        lib.clearHistory()
        XCTAssertEqual(Set(lib.clips.compactMap(\.text)), ["a", "n"])
    }

    func testDeletePinboardAndFilter() {
        var lib = Library()
        lib.pinboards = [Pinboard(id: "p", name: "P", colorHex: "#f00", createdAt: Date())]
        let (a, _) = lib.add(t("Hallo Welt"))
        lib.add(t("https://x.de"))
        lib.togglePin(a, "p")
        XCTAssertEqual(lib.filtered(query: "WELT").count, 1)
        XCTAssertEqual(lib.filtered(kind: .link).first?.text, "https://x.de")
        XCTAssertEqual(lib.filtered(keptOnly: true).first?.text, "Hallo Welt")
        lib.deletePinboard("p")
        XCTAssertTrue(lib.pinboards.isEmpty)
        XCTAssertTrue(lib.clips.allSatisfy { $0.pinboardIds.isEmpty })
    }

    func testEditTextRedetects() {
        var lib = Library()
        let (a, _) = lib.add(t("hallo"))
        lib.editText(a, "#fff")
        XCTAssertEqual(lib.clips[0].kind, .color)
        XCTAssertEqual(lib.clips[0].hash, Detect.hash("#fff"))
    }

    func testCodableRoundtrip() throws {
        var lib = Library()
        lib.add(t("x"))
        let data = try JSONEncoder().encode(lib)
        XCTAssertEqual(try JSONDecoder().decode(Library.self, from: data), lib)
    }
}
