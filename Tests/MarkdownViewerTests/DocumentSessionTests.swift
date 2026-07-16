import XCTest
@testable import MarkdownViewer

@MainActor
final class DocumentSessionTests: XCTestCase {
    func testEditorChangeIsPersistedAfterDebounce() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("test.md")
        try Data("old".utf8).write(to: file)

        let session = try DocumentSession(url: file)
        session.editorChanged("new")
        try await Task.sleep(for: .milliseconds(550))

        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "new")
    }

    func testExplicitFlushWritesImmediately() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("test.md")
        try Data("old".utf8).write(to: file)

        let session = try DocumentSession(url: file)
        session.editorChanged("immediate")
        session.flush()

        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "immediate")
    }
}

