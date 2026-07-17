import XCTest
@testable import PaperMD

final class WorkspaceItemTests: XCTestCase {
    func testRecognizedMarkdownExtensions() {
        XCTAssertTrue(WorkspaceItem.markdownExtensions.contains("md"))
        XCTAssertTrue(WorkspaceItem.markdownExtensions.contains("markdown"))
        XCTAssertFalse(WorkspaceItem.markdownExtensions.contains("txt"))
    }

    func testScanIgnoresSymbolicLinksInsideWorkspace() throws {
        let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let workspace = parent.appendingPathComponent("Workspace")
        let external = parent.appendingPathComponent("External")
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: external, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: parent) }

        try Data("safe".utf8).write(to: workspace.appendingPathComponent("Safe.md"))
        try Data("private".utf8).write(to: external.appendingPathComponent("Private.md"))
        try FileManager.default.createSymbolicLink(
            at: workspace.appendingPathComponent("External"),
            withDestinationURL: external
        )
        try FileManager.default.createSymbolicLink(
            at: workspace.appendingPathComponent("Loop"),
            withDestinationURL: workspace
        )

        XCTAssertEqual(try WorkspaceItem.scan(root: workspace).map(\.name), ["Safe.md"])
    }

    func testContainmentDoesNotAcceptSiblingWithSharedPrefix() {
        let root = URL(fileURLWithPath: "/tmp/notes")
        XCTAssertTrue(WorkspaceItem.contains(root.appendingPathComponent("file.md"), in: root))
        XCTAssertFalse(WorkspaceItem.contains(URL(fileURLWithPath: "/tmp/notes-private/file.md"), in: root))
    }
}
