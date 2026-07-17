import XCTest
@testable import PaperMD

@MainActor
final class WorkspaceStoreTests: XCTestCase {
    func testOpeningDocumentLoadsMarkdownFilesFromItsFolder() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let openedFile = directory.appendingPathComponent("First.md")
        let siblingFile = directory.appendingPathComponent("Second.markdown")
        try Data("# First".utf8).write(to: openedFile)
        try Data("# Second".utf8).write(to: siblingFile)
        try Data("ignored".utf8).write(to: directory.appendingPathComponent("Notes.txt"))

        let workspace = WorkspaceStore(bookmarkKey: "PaperMDTests.\(UUID().uuidString)")
        workspace.openDocument(openedFile)
        defer { workspace.closeWorkspace() }

        XCTAssertEqual(workspace.rootURL?.resolvingSymlinksInPath().path, directory.resolvingSymlinksInPath().path)
        XCTAssertEqual(workspace.selectedFile?.resolvingSymlinksInPath().path, openedFile.resolvingSymlinksInPath().path)
        XCTAssertEqual(workspace.items.map(\.name), ["First.md", "Second.markdown"])
    }

    func testClosingWorkspaceClearsFolderAndDocument() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("Document.md")
        try Data("# Document".utf8).write(to: file)

        let workspace = WorkspaceStore(bookmarkKey: "PaperMDTests.\(UUID().uuidString)")
        workspace.openDocument(file)
        workspace.closeWorkspace()

        XCTAssertNil(workspace.rootURL)
        XCTAssertNil(workspace.selectedFile)
        XCTAssertNil(workspace.session)
        XCTAssertTrue(workspace.items.isEmpty)
    }

    func testSelectingFolderDoesNotTryToOpenItAsDocument() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("Document.md")
        try Data("# Document".utf8).write(to: file)

        let workspace = WorkspaceStore(bookmarkKey: "PaperMDTests.\(UUID().uuidString)")
        workspace.select(file)
        workspace.select(directory)

        XCTAssertEqual(workspace.selectedFile, file)
        XCTAssertNotNil(workspace.session)
        XCTAssertNil(workspace.errorMessage)
    }

    func testScrollPositionsAreRememberedPerDocument() {
        let workspace = WorkspaceStore(bookmarkKey: "PaperMDTests.\(UUID().uuidString)")
        let first = URL(fileURLWithPath: "/tmp/First.md")
        let second = URL(fileURLWithPath: "/tmp/Second.md")

        XCTAssertEqual(workspace.scrollPosition(for: first), 0)
        workspace.rememberScrollPosition(320, for: first)

        XCTAssertEqual(workspace.scrollPosition(for: first), 320)
        XCTAssertEqual(workspace.scrollPosition(for: second), 0)
    }
}
