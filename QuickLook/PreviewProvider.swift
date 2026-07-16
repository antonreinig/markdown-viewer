import QuickLookUI
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler handler: @escaping (QLPreviewReply?, (any Error)?) -> Void
    ) {
        do {
            let data = try Data(contentsOf: request.fileURL)
            guard let markdown = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileReadInapplicableStringEncoding)
            }
            let html = MarkdownPreviewDocument.html(markdown: markdown, title: request.fileURL.lastPathComponent)
            let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 900, height: 1100)) { _ in
                Data(html.utf8)
            }
            reply.stringEncoding = .utf8
            reply.title = request.fileURL.lastPathComponent
            handler(reply, nil)
        } catch {
            handler(nil, error)
        }
    }
}
