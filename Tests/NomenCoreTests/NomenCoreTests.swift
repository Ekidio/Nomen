import XCTest
@testable import NomenCore

final class RenameRuleTests: XCTestCase {
    private func names(_ files: [String], _ configure: (inout RenameSettings) -> Void) throws -> [String] {
        var settings = RenameSettings()
        configure(&settings)
        return try files.enumerated().map { index, name in
            try RenameRule.newName(for: FileInfo(name: name), index: index, settings: settings)
        }
    }

    func testSequenceKeepsExtension() throws {
        let result = try names(["IMG_9921.JPG", "IMG_9922.heic", "notes.final.txt", "README"]) {
            $0.mode = .sequence
            $0.text = "Nyaralas"
        }
        XCTAssertEqual(result, ["Nyaralas_001.JPG", "Nyaralas_002.heic", "Nyaralas_003.txt", "Nyaralas_004"])
    }

    func testSequenceOptions() throws {
        let result = try names(["a.png", "b.png"]) {
            $0.mode = .sequence
            $0.sequenceStart = 9
            $0.sequenceStep = 5
            $0.sequenceDigits = 2
            $0.sequenceNumberFirst = true
            $0.sequenceSeparator = " - "
            $0.sequenceKeepName = true
        }
        XCTAssertEqual(result, ["09 - a.png", "14 - b.png"])
    }

    func testSequenceWithoutTextIsJustNumber() throws {
        XCTAssertEqual(try names(["x.pdf"]) { $0.mode = .sequence }, ["001.pdf"])
    }

    func testExtensionToggleOff() throws {
        let result = try names(["photo.jpg"]) {
            $0.mode = .changeCase
            $0.caseStyle = .upper
            $0.keepExtension = false
        }
        XCTAssertEqual(result, ["PHOTO.JPG"])
    }

    func testDotfileAndFolder() throws {
        var s = RenameSettings()
        s.mode = .append
        s.text = "_x"
        XCTAssertEqual(try RenameRule.newName(for: FileInfo(name: ".gitignore"), index: 0, settings: s), ".gitignore_x")
        XCTAssertEqual(try RenameRule.newName(for: FileInfo(name: "v1.2", isDirectory: true), index: 0, settings: s), "v1.2_x")
    }

    func testReplaceModes() throws {
        let files = ["a-b-a.txt"]
        XCTAssertEqual(try names(files) { $0.mode = .replaceFirst; $0.find = "a"; $0.text = "X" }, ["X-b-a.txt"])
        XCTAssertEqual(try names(files) { $0.mode = .replaceLast; $0.find = "a"; $0.text = "X" }, ["a-b-X.txt"])
        XCTAssertEqual(try names(files) { $0.mode = .replaceAll; $0.find = "A"; $0.text = "X"; $0.caseSensitive = false }, ["X-b-X.txt"])
        XCTAssertEqual(try names(files) { $0.mode = .replaceAll; $0.find = "A"; $0.text = "X" }, ["a-b-a.txt"])
    }

    func testWildcardAndRegex() throws {
        XCTAssertEqual(try names(["IMG_1234 copy.jpg"]) { $0.mode = .wildcard; $0.find = "IMG_????"; $0.text = "Kep" }, ["Kep copy.jpg"])
        XCTAssertEqual(try names(["2024-05-01 report.pdf"]) {
            $0.mode = .regex
            $0.find = #"(\d{4})-(\d{2})-(\d{2})"#
            $0.text = "$3.$2.$1"
        }, ["01.05.2024 report.pdf"])
        XCTAssertThrowsError(try names(["a.txt"]) { $0.mode = .regex; $0.find = "(" })
    }

    func testRemoveAndInsert() throws {
        XCTAssertEqual(try names(["abcdef.txt"]) { $0.mode = .removeCharacters; $0.removeCount = 2; $0.removeOffset = 1 }, ["adef.txt"])
        XCTAssertEqual(try names(["abcdef.txt"]) { $0.mode = .removeCharacters; $0.removeCount = 2; $0.removeFrom = .end }, ["abcd.txt"])
        XCTAssertEqual(try names(["abc.txt"]) { $0.mode = .removeCharacters; $0.removeCount = 10 }, [".txt"])
        XCTAssertEqual(try names(["abc.txt"]) { $0.mode = .insertCharacters; $0.text = "-"; $0.insertOffset = 1; $0.insertFrom = .end }, ["ab-c.txt"])
    }

    func testCaseAndDate() throws {
        XCTAssertEqual(try names(["hELLO wORLD.md"]) { $0.mode = .changeCase; $0.caseStyle = .sentence }, ["Hello world.md"])
        var s = RenameSettings()
        s.mode = .date
        s.dateFormat = "yyyyMMdd"
        let file = FileInfo(name: "scan.pdf", modified: Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(try RenameRule.newName(for: file, index: 0, settings: s), "20231114 scan.pdf")
    }
}

final class RenameEngineTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func touch(_ name: String, _ contents: String = "") throws -> URL {
        let url = dir.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func listing() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: dir.path).sorted()
    }

    func testSwapAndUndo() throws {
        let a = try touch("a.txt", "A")
        let b = try touch("b.txt", "B")
        let plan = [RenamePlanItem(source: a, newName: "b.txt"), RenamePlanItem(source: b, newName: "a.txt")]
        XCTAssertTrue(RenameEngine.validate(plan).isEmpty)
        let done = try RenameEngine.perform(plan)
        XCTAssertEqual(try String(contentsOf: dir.appendingPathComponent("b.txt"), encoding: .utf8), "A")
        try RenameEngine.perform(RenameEngine.undoPlan(for: done))
        XCTAssertEqual(try String(contentsOf: a, encoding: .utf8), "A")
        XCTAssertEqual(try listing(), ["a.txt", "b.txt"])
    }

    func testCaseOnlyRename() throws {
        let a = try touch("photo.jpg")
        let plan = [RenamePlanItem(source: a, newName: "Photo.jpg")]
        XCTAssertTrue(RenameEngine.validate(plan).isEmpty)
        try RenameEngine.perform(plan)
        XCTAssertEqual(try listing(), ["Photo.jpg"])
    }

    func testValidationIssues() throws {
        let a = try touch("a.txt")
        let b = try touch("b.txt")
        _ = try touch("taken.txt")
        let issues = RenameEngine.validate([
            RenamePlanItem(source: a, newName: "same.txt"),
            RenamePlanItem(source: b, newName: "same.txt"),
        ])
        XCTAssertEqual(issues, [0: .duplicate, 1: .duplicate])
        XCTAssertEqual(RenameEngine.validate([RenamePlanItem(source: a, newName: "taken.txt")]), [0: .alreadyExists])
        XCTAssertEqual(RenameEngine.validate([RenamePlanItem(source: a, newName: "x/y.txt")]), [0: .invalidCharacters])
        XCTAssertEqual(RenameEngine.validate([RenamePlanItem(source: a, newName: "")]), [0: .empty])
        // Taking the name of an unchanged file in the batch is a duplicate.
        XCTAssertEqual(RenameEngine.validate([
            RenamePlanItem(source: a, newName: "b.txt"),
            RenamePlanItem(source: b, newName: "b.txt"),
        ]), [0: .duplicate, 1: .duplicate])
    }

    func testFailureRollsBack() throws {
        let a = try touch("a.txt")
        let missing = dir.appendingPathComponent("missing.txt")
        let plan = [RenamePlanItem(source: a, newName: "z.txt"), RenamePlanItem(source: missing, newName: "y.txt")]
        XCTAssertThrowsError(try RenameEngine.perform(plan))
        XCTAssertEqual(try listing(), ["a.txt"])
    }
}
