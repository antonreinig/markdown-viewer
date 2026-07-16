import Foundation

struct WorkspaceItem: Identifiable, Hashable, Sendable {
    let url: URL
    let isDirectory: Bool
    var children: [WorkspaceItem]?

    var id: URL { url }
    var name: String { url.lastPathComponent }

    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown"]

    static func scan(root: URL, fileManager: FileManager = .default) throws -> [WorkspaceItem] {
        try scanDirectory(root, fileManager: fileManager)
    }

    private static func scanDirectory(_ directory: URL, fileManager: FileManager) throws -> [WorkspaceItem] {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isHiddenKey, .nameKey]
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants]
        )

        return try urls.compactMap { url in
            let values = try url.resourceValues(forKeys: keys)
            let name = values.name ?? url.lastPathComponent
            if values.isHidden == true || ignoredDirectoryNames.contains(name) { return nil }
            if values.isDirectory == true {
                let children = try scanDirectory(url, fileManager: fileManager)
                guard !children.isEmpty else { return nil }
                return WorkspaceItem(url: url, isDirectory: true, children: children)
            }
            guard markdownExtensions.contains(url.pathExtension.lowercased()) else { return nil }
            return WorkspaceItem(url: url, isDirectory: false, children: nil)
        }
        .sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static let ignoredDirectoryNames: Set<String> = [
        ".git", ".build", "DerivedData", "node_modules", "Pods"
    ]
}

