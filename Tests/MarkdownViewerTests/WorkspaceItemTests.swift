import XCTest
@testable import MarkdownViewer

final class WorkspaceItemTests: XCTestCase {
    func testRecognizedMarkdownExtensions() {
        XCTAssertTrue(WorkspaceItem.markdownExtensions.contains("md"))
        XCTAssertTrue(WorkspaceItem.markdownExtensions.contains("markdown"))
        XCTAssertFalse(WorkspaceItem.markdownExtensions.contains("txt"))
    }
}

