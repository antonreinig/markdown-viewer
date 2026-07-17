import Foundation
import Markdown

struct MarkdownHTMLRenderer: MarkupVisitor {
    typealias Result = String
    private var isRenderingTableHead = false

    mutating func defaultVisit(_ markup: Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    mutating func visitText(_ text: Text) -> String { escape(text.string) }
    mutating func visitParagraph(_ paragraph: Paragraph) -> String { "<p>\(defaultVisit(paragraph))</p>" }
    mutating func visitHeading(_ heading: Heading) -> String { "<h\(heading.level)>\(defaultVisit(heading))</h\(heading.level)>" }
    mutating func visitStrong(_ strong: Strong) -> String { "<strong>\(defaultVisit(strong))</strong>" }
    mutating func visitEmphasis(_ emphasis: Emphasis) -> String { "<em>\(defaultVisit(emphasis))</em>" }
    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String { "<s>\(defaultVisit(strikethrough))</s>" }
    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String { "<code>\(escape(inlineCode.code))</code>" }
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let language = codeBlock.language.map { " class=\"language-\(escapeAttribute($0))\"" } ?? ""
        return "<pre><code\(language)>\(escape(codeBlock.code))</code></pre>"
    }
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String { "<blockquote>\(defaultVisit(blockQuote))</blockquote>" }
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String { "<ul>\(defaultVisit(unorderedList))</ul>" }
    mutating func visitOrderedList(_ orderedList: OrderedList) -> String { "<ol>\(defaultVisit(orderedList))</ol>" }
    mutating func visitListItem(_ listItem: ListItem) -> String {
        let checkbox: String
        switch listItem.checkbox {
        case .checked?: checkbox = "<input type=\"checkbox\" checked disabled> "
        case .unchecked?: checkbox = "<input type=\"checkbox\" disabled> "
        case nil: checkbox = ""
        }
        return "<li>\(checkbox)\(defaultVisit(listItem))</li>"
    }
    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String { "<hr>" }
    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String { "\n" }
    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String { "<br>" }
    mutating func visitLink(_ link: Link) -> String {
        guard let destination = link.destination, isSafeURL(destination) else { return defaultVisit(link) }
        return "<a href=\"\(escapeAttribute(destination))\">\(defaultVisit(link))</a>"
    }
    mutating func visitImage(_ image: Image) -> String {
        guard let source = image.source, isSafeImageURL(source) else { return escape(image.plainText) }
        return "<img src=\"\(escapeAttribute(source))\" alt=\"\(escapeAttribute(image.plainText))\">"
    }
    mutating func visitTable(_ table: Table) -> String { "<table>\(defaultVisit(table))</table>" }
    mutating func visitTableHead(_ tableHead: Table.Head) -> String {
        isRenderingTableHead = true
        let content = defaultVisit(tableHead)
        isRenderingTableHead = false
        return "<thead><tr>\(content)</tr></thead>"
    }
    mutating func visitTableBody(_ tableBody: Table.Body) -> String { "<tbody>\(defaultVisit(tableBody))</tbody>" }
    mutating func visitTableRow(_ tableRow: Table.Row) -> String { "<tr>\(defaultVisit(tableRow))</tr>" }
    mutating func visitTableCell(_ tableCell: Table.Cell) -> String {
        let tag = isRenderingTableHead ? "th" : "td"
        return "<\(tag)>\(defaultVisit(tableCell))</\(tag)>"
    }

    private func isSafeURL(_ value: String) -> Bool {
        guard let scheme = URL(string: value)?.scheme?.lowercased() else { return true }
        return ["http", "https", "mailto"].contains(scheme)
    }

    private func isSafeImageURL(_ value: String) -> Bool {
        guard let scheme = URL(string: value)?.scheme?.lowercased() else { return true }
        return ["file", "data"].contains(scheme)
    }

    private func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func escapeAttribute(_ value: String) -> String {
        escape(value).replacingOccurrences(of: "\"", with: "&quot;")
    }
}

enum MarkdownPreviewDocument {
    static func html(markdown: String, title: String) -> String {
        let (frontMatter, content) = splitFrontMatter(from: markdown)
        let document = Document(parsing: content, options: [.parseBlockDirectives, .parseSymbolLinks])
        var renderer = MarkdownHTMLRenderer()
        let metadata = frontMatter.map { "<aside class=\"front-matter\"><strong>Document metadata</strong><pre>\(escapeHTML($0))</pre></aside>" } ?? ""
        let body = metadata + renderer.visit(document)
        return """
        <!doctype html>
        <html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src data: file:">
        <style>
        :root{color-scheme:light dark;font:16px/1.58 -apple-system,BlinkMacSystemFont,sans-serif}body{max-width:820px;margin:0 auto;padding:48px 58px 100px;color:light-dark(#1d1d1f,#f5f5f7)}h1{font-size:2.1em;letter-spacing:-.035em}h2{font-size:1.55em;margin-top:1.5em}a{color:-apple-system-link}blockquote{border-left:3px solid light-dark(#d2d2d7,#424245);color:light-dark(#6e6e73,#a1a1a6);margin:1em 0;padding-left:1em}code{background:light-dark(#f5f5f7,#242426);border-radius:5px;padding:.12em .35em;font: .9em SFMono-Regular,monospace}pre{background:light-dark(#f5f5f7,#242426);border-radius:9px;overflow:auto;padding:16px 18px}pre code{background:none;padding:0}img{max-width:100%}table{border-collapse:collapse;width:100%}th,td{border:1px solid light-dark(#d2d2d7,#424245);padding:8px 10px;text-align:left}hr{border:0;border-top:1px solid light-dark(#d2d2d7,#424245);margin:2em 0}.front-matter{background:light-dark(#f5f5f7,#242426);border:1px solid light-dark(#d2d2d7,#424245);border-radius:9px;color:light-dark(#6e6e73,#a1a1a6);font-size:.82em;margin:0 0 2em;padding:12px 14px}.front-matter pre{background:none;margin:.5em 0 0;padding:0;white-space:pre-wrap}
        </style><title>\(escapeTitle(title))</title></head><body>\(body)</body></html>
        """
    }

    private static func escapeTitle(_ title: String) -> String {
        title.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func escapeHTML(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func splitFrontMatter(from markdown: String) -> (String?, String) {
        guard markdown.hasPrefix("---\n") || markdown.hasPrefix("---\r\n") else { return (nil, markdown) }
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
        guard let closing = lines.dropFirst().firstIndex(where: { $0 == "---" || $0 == "..." }) else { return (nil, markdown) }
        let metadata = lines[1..<closing].joined(separator: "\n")
        let content = lines.dropFirst(closing + 1).joined(separator: "\n")
        return (metadata, content)
    }
}
