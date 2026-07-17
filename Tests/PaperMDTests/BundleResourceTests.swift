import XCTest
@testable import PaperMD

final class BundleResourceTests: XCTestCase {
    func testAutomaticUpdateConfigurationIsBundled() {
        XCTAssertEqual(
            Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
            "https://github.com/antonreinig/paper.md/releases/latest/download/appcast.xml"
        )
        XCTAssertEqual(
            Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
            "rU+HfNnTmiFeu/hQ97GzjSR9pBUjjujgGhPV6dnRUmc="
        )
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "SUEnableInstallerLauncherService") as? Bool, true)
    }

    func testSparkleLicenseNoticeIsBundled() throws {
        let noticeURL = try XCTUnwrap(Bundle.main.url(forResource: "Sparkle", withExtension: "txt"))
        let notice = try String(contentsOf: noticeURL, encoding: .utf8)
        XCTAssertTrue(notice.contains("Permission is hereby granted, free of charge"))
    }

    func testEditorEntryPointIsBundled() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "index", withExtension: "html"))
        let html = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(html.contains("paper.md Editor"))
    }

    func testEditorScriptIsBundled() throws {
        let indexURL = try XCTUnwrap(Bundle.main.url(forResource: "index", withExtension: "html"))
        let html = try String(contentsOf: indexURL, encoding: .utf8)
        let pattern = #"src=\"\./assets/([^\"]+\.js)\""#
        let expression = try NSRegularExpression(pattern: pattern)
        let range = NSRange(html.startIndex..., in: html)
        let match = try XCTUnwrap(expression.firstMatch(in: html, range: range))
        let filenameRange = try XCTUnwrap(Range(match.range(at: 1), in: html))
        let script = indexURL.deletingLastPathComponent()
            .appendingPathComponent("assets")
            .appendingPathComponent(String(html[filenameRange]))
        XCTAssertTrue(FileManager.default.fileExists(atPath: script.path))
    }

    func testEditorSourceMapsAreNotBundled() throws {
        let indexURL = try XCTUnwrap(Bundle.main.url(forResource: "index", withExtension: "html"))
        let assetsURL = indexURL.deletingLastPathComponent().appendingPathComponent("assets")
        let assets = try FileManager.default.contentsOfDirectory(at: assetsURL, includingPropertiesForKeys: nil)
        XCTAssertFalse(assets.contains { $0.pathExtension == "map" })
    }

    func testQuickLookExtensionIsBundledAndRegisteredForMarkdown() throws {
        let pluginsURL = try XCTUnwrap(Bundle.main.builtInPlugInsURL)
        let extensionURL = pluginsURL.appendingPathComponent("PaperMDQuickLook.appex")
        let extensionBundle = try XCTUnwrap(Bundle(url: extensionURL))
        let extensionDictionary = try XCTUnwrap(extensionBundle.infoDictionary?["NSExtension"] as? [String: Any])
        let attributes = try XCTUnwrap(extensionDictionary["NSExtensionAttributes"] as? [String: Any])

        XCTAssertEqual(extensionDictionary["NSExtensionPointIdentifier"] as? String, "com.apple.quicklook.preview")
        XCTAssertEqual(extensionDictionary["NSExtensionPrincipalClass"] as? String, "PaperMDQuickLook.PreviewProvider")
        XCTAssertEqual(attributes["QLIsDataBasedPreview"] as? Bool, true)
        XCTAssertEqual(attributes["QLSupportedContentTypes"] as? [String], ["net.daringfireball.markdown"])
    }

    func testThumbnailExtensionIsBundledAndRegisteredForMarkdown() throws {
        let pluginsURL = try XCTUnwrap(Bundle.main.builtInPlugInsURL)
        let extensionURL = pluginsURL.appendingPathComponent("PaperMDThumbnail.appex")
        let extensionBundle = try XCTUnwrap(Bundle(url: extensionURL))
        let extensionDictionary = try XCTUnwrap(extensionBundle.infoDictionary?["NSExtension"] as? [String: Any])
        let attributes = try XCTUnwrap(extensionDictionary["NSExtensionAttributes"] as? [String: Any])

        XCTAssertEqual(extensionDictionary["NSExtensionPointIdentifier"] as? String, "com.apple.quicklook.thumbnail")
        XCTAssertEqual(attributes["QLSupportedContentTypes"] as? [String], ["net.daringfireball.markdown"])
        XCTAssertEqual(attributes["QLThumbnailMinimumDimension"] as? Int, 0)
    }
}
