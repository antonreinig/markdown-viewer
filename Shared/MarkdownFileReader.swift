import Foundation

enum MarkdownFileReader {
    static let maximumByteCount = 16 * 1_024 * 1_024
    private static let chunkByteCount = 64 * 1_024

    static func read(from url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var data = Data()
        while data.count <= maximumByteCount {
            let remaining = maximumByteCount + 1 - data.count
            let chunk = try handle.read(upToCount: min(chunkByteCount, remaining)) ?? Data()
            guard !chunk.isEmpty else { break }
            data.append(chunk)
        }

        guard data.count <= maximumByteCount else {
            throw CocoaError(.fileReadTooLarge)
        }
        guard let markdown = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return markdown
    }
}
