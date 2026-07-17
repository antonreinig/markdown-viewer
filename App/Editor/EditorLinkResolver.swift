import Foundation

enum EditorLinkDestination: Equatable {
    case anchor(String)
    case external(URL)
    case localFile(URL)
}

enum EditorLinkResolver {
    static func resolve(
        _ value: String,
        documentURL: URL,
        workspaceRootURL: URL,
        fileManager: FileManager = .default
    ) -> EditorLinkDestination? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("#") {
            guard let fragment = String(trimmed.dropFirst()).removingPercentEncoding else { return nil }
            return .anchor(fragment)
        }

        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() {
            if ["http", "https", "mailto"].contains(scheme) {
                return .external(url)
            }
            guard scheme == "file" else { return nil }
            return validatedLocalFile(url, workspaceRootURL: workspaceRootURL, fileManager: fileManager)
        }

        let path = trimmed.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? trimmed
        let decodedPath = path.removingPercentEncoding ?? path
        let base = documentURL.deletingLastPathComponent()
        let url = URL(fileURLWithPath: decodedPath, relativeTo: base)
        return validatedLocalFile(url, workspaceRootURL: workspaceRootURL, fileManager: fileManager)
    }

    private static func validatedLocalFile(
        _ url: URL,
        workspaceRootURL: URL,
        fileManager: FileManager
    ) -> EditorLinkDestination? {
        guard url.isFileURL, url.host == nil || url.host?.isEmpty == true || url.host == "localhost" else { return nil }
        guard (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true else { return nil }

        let canonicalURL = url.standardizedFileURL.resolvingSymlinksInPath()
        guard WorkspaceItem.contains(canonicalURL, in: workspaceRootURL),
              let values = try? canonicalURL.resourceValues(forKeys: [.isRegularFileKey]),
              values.isRegularFile == true,
              !fileManager.isExecutableFile(atPath: canonicalURL.path) else { return nil }
        return .localFile(canonicalURL)
    }
}
