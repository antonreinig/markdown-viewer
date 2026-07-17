# Markdown compatibility

paper.md uses one predictable compatibility profile for every Markdown document. Filename extensions do not select a parser flavor.

## Editable baseline

The WYSIWYG editor supports CommonMark plus the GitHub Flavored Markdown features tables, fenced code blocks, task lists, strikethrough, and autolinks. It also provides editable links, images, highlight (`==text==`), and superscript (`^text^`).

## Lossless extended syntax

The following constructs have dedicated visual representations and are serialized back to Markdown without discarding their source:

- YAML front matter
- Footnote references and definitions
- Inline and display math
- Wiki links
- Raw HTML and HTML comments
- Colon directives and admonition blocks

Unrendered extended syntax is deliberately shown as a compact Markdown element instead of being interpreted as ordinary rich text. This ensures editing another part of the document does not silently remove it.

Compatibility behavior is covered by `Editor/test-fixtures/compatibility.md` and the editor round-trip tests. The Quick Look preview uses the same CommonMark/GFM baseline and recognizes YAML front matter as document metadata.
