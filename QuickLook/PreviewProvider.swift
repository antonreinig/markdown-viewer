import QuickLookUI
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler handler: @escaping (QLPreviewReply?, (any Error)?) -> Void
    ) {
        do {
            let markdown = try MarkdownFileReader.read(from: request.fileURL)
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
