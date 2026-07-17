import AppKit
import QuickLookThumbnailing

final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, (any Error)?) -> Void
    ) {
        do {
            let data = try Data(contentsOf: request.fileURL)
            guard let markdown = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileReadInapplicableStringEncoding)
            }
            let preview = MarkdownThumbnailPreview(markdown: markdown, filename: request.fileURL.lastPathComponent)
            let size = thumbnailSize(fitting: request.maximumSize)
            let reply = QLThumbnailReply(contextSize: size) { context in
                preview.draw(in: context, size: size)
                return true
            }
            handler(reply, nil)
        } catch {
            handler(nil, error)
        }
    }

    private func thumbnailSize(fitting maximumSize: CGSize) -> CGSize {
        let aspectRatio = CGFloat(0.72)
        if maximumSize.width / maximumSize.height < aspectRatio {
            return CGSize(width: maximumSize.width, height: maximumSize.width / aspectRatio)
        }
        return CGSize(width: maximumSize.height * aspectRatio, height: maximumSize.height)
    }
}

private struct MarkdownThumbnailPreview: Sendable {
    let title: String
    let lines: [String]

    init(markdown: String, filename: String) {
        let sourceLines = markdown.components(separatedBy: .newlines)
        let heading = sourceLines.lazy
            .map(Self.cleanedLine)
            .first(where: { !$0.isEmpty })
        let resolvedTitle = heading ?? filename
        title = resolvedTitle
        lines = sourceLines
            .map(Self.cleanedLine)
            .filter { !$0.isEmpty && $0 != resolvedTitle }
    }

    func draw(in context: CGContext, size: CGSize) {
        let scale = max(size.width / 360, 0.2)
        let bounds = CGRect(origin: .zero, size: size)
        context.setFillColor(NSColor.white.cgColor)
        context.fill(bounds)

        let margin = 30 * scale
        let textWidth = size.width - margin * 2
        let titleFont = NSFont.systemFont(ofSize: 25 * scale, weight: .bold)
        let bodyFont = NSFont.systemFont(ofSize: 12 * scale)
        let primary = NSColor(calibratedWhite: 0.08, alpha: 1)
        let secondary = NSColor(calibratedWhite: 0.25, alpha: 1)

        var y = size.height - margin - titleFont.pointSize
        draw(title, in: context, rect: CGRect(x: margin, y: y, width: textWidth, height: titleFont.pointSize * 1.25), font: titleFont, color: primary)
        y -= titleFont.pointSize * 1.8

        context.setStrokeColor(NSColor(calibratedWhite: 0.82, alpha: 1).cgColor)
        context.setLineWidth(max(scale, 0.5))
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: size.width - margin, y: y))
        context.strokePath()
        y -= 22 * scale

        let lineHeight = 19 * scale
        for line in lines.prefix(18) where y > margin {
            draw(line, in: context, rect: CGRect(x: margin, y: y, width: textWidth, height: lineHeight), font: bodyFont, color: secondary)
            y -= lineHeight
        }
    }

    private func draw(_ string: String, in context: CGContext, rect: CGRect, font: NSFont, color: NSColor) {
        let attributed = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color])
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        attributed.draw(with: rect, options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin])
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func cleanedLine(_ line: String) -> String {
        var value = line.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        while value.first == "#" { value.removeFirst() }
        for prefix in ["- [ ] ", "- [x] ", "- [X] ", "- ", "* ", "> "] where value.hasPrefix(prefix) {
            value.removeFirst(prefix.count)
            break
        }
        return value.trimmingCharacters(in: .whitespaces)
    }
}
