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

final class V3LogicTests: XCTestCase {
    func testCleanLink() {
        XCTAssertEqual(Detect.cleanLink("https://x.de/a?utm_source=nl&id=5&fbclid=abc"), "https://x.de/a?id=5")
        XCTAssertEqual(Detect.cleanLink("https://open.spotify.com/track/1?si=xyz"), "https://open.spotify.com/track/1")
        XCTAssertEqual(Detect.cleanLink("https://x.de/a?id=5"), "https://x.de/a?id=5")
    }

    func testSensitive() {
        XCTAssertTrue(Detect.isSensitive("483920"))
        XCTAssertTrue(Detect.isSensitive("Tr0ub4dor&3x!"))
        XCTAssertFalse(Detect.isSensitive("Hallo Welt"))
        XCTAssertFalse(Detect.isSensitive("12"))
        XCTAssertFalse(Detect.isSensitive("https://x.de/Ab1!"))
    }

    func testExpiryAndPurge() {
        var lib = Library()
        let now = Date(timeIntervalSince1970: 1000)
        lib.add(lib.textClip("483920", now: now), now: now)
        lib.add(lib.textClip("normal"), now: now)
        XCTAssertEqual(lib.filtered(now: now).count, 2)
        let later = now.addingTimeInterval(Library.sensitiveLifetime + 1)
        XCTAssertEqual(lib.filtered(now: later).map(\.text), ["normal"])
        lib.purgeExpired(now: later)
        XCTAssertEqual(lib.clips.count, 1)
        lib.autoDeleteSensitive = false
        XCTAssertNil(lib.textClip("483920").expiresAt)
    }

    func testTextClipCleansLinks() {
        let lib = Library()
        XCTAssertEqual(lib.textClip("https://x.de/?utm_medium=a").text, "https://x.de/")
    }

    func testTemplates() {
        let now = Date(timeIntervalSince1970: 0)
        let de = Locale(identifier: "de_DE")
        let (out, back) = Templates.expand("Hallo {Cursor}, heute ist {Wochentag}. Kopiert: {clipboard}", now: now, locale: de, clipboard: "X")
        XCTAssertTrue(out.hasPrefix("Hallo , heute ist "))
        XCTAssertTrue(out.hasSuffix("Kopiert: X"))
        XCTAssertEqual(back, out.count - "Hallo ".count)
        XCTAssertNil(Templates.expand("ohne").1)
        XCTAssertTrue(Templates.needsClipboard("{Zwischenablage}"))
    }

    func testTransforms() {
        XCTAssertEqual(Transform.bullets.apply("a\n\nb"), "• a\n• b")
        XCTAssertEqual(Transform.numbered.apply("a\nb"), "1. a\n2. b")
        XCTAssertEqual(Transform.joinLines.apply("a\n b \n"), "a b")
        XCTAssertEqual(Transform.trimEmptyLines.apply("a\n\n\nb"), "a\nb")
        XCTAssertEqual(Transform.upper.apply("ab"), "AB")
    }
}
