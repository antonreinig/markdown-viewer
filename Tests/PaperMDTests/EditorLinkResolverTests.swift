import XCTest
@testable import PaperMD

final class EditorLinkResolverTests: XCTestCase {
    func testAllowsExternalWebAndMailLinks() {
        let (document, root) = fixtureURLs()
        XCTAssertEqual(
            EditorLinkResolver.resolve("https://example.com", documentURL: document, workspaceRootURL: root),
            .external(URL(string: "https://example.com")!)
        )
        XCTAssertNotNil(EditorLinkResolver.resolve("mailto:hello@example.com", documentURL: document, workspaceRootURL: root))
        XCTAssertNil(EditorLinkResolver.resolve("custom:payload", documentURL: document, workspaceRootURL: root))
    }

    func testAllowsOnlyRegularNonExecutableFilesInsideWorkspace() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let nested = root.appendingPathComponent("Notes")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let document = nested.appendingPathComponent("Current.md")
        let linked = root.appendingPathComponent("Linked.md")
        let executable = root.appendingPathComponent("run.md")
        try Data("current".utf8).write(to: document)
        try Data("linked".utf8).write(to: linked)
        try Data("run".utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        XCTAssertEqual(
            EditorLinkResolver.resolve("../Linked.md", documentURL: document, workspaceRootURL: root),
            .localFile(linked)
        )
        XCTAssertNil(EditorLinkResolver.resolve("../run.md", documentURL: document, workspaceRootURL: root))
        XCTAssertNil(EditorLinkResolver.resolve("file:///Applications/Calculator.app", documentURL: document, workspaceRootURL: root))
    }

    func testRejectsTraversalAndSymbolicLinks() throws {
        let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let root = parent.appendingPathComponent("Workspace")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: parent) }

        let document = root.appendingPathComponent("Current.md")
        let external = parent.appendingPathComponent("External.md")
        let symlink = root.appendingPathComponent("Linked.md")
        try Data("current".utf8).write(to: document)
        try Data("external".utf8).write(to: external)
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: external)

        XCTAssertNil(EditorLinkResolver.resolve("../External.md", documentURL: document, workspaceRootURL: root))
        XCTAssertNil(EditorLinkResolver.resolve("Linked.md", documentURL: document, workspaceRootURL: root))
        XCTAssertEqual(
            EditorLinkResolver.resolve("#section", documentURL: document, workspaceRootURL: root),
            .anchor("section")
        )
    }

    private func fixtureURLs() -> (URL, URL) {
        let root = URL(fileURLWithPath: "/tmp/workspace")
        return (root.appendingPathComponent("Document.md"), root)
    }
}
