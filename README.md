# Markdown Viewer

A focused, open-source WYSIWYG Markdown editor built for macOS and AI-assisted file workflows.

Markdown Viewer opens a repository or folder like an IDE, lets you browse its Markdown files, saves edits continuously, and reloads files when another process or AI agent changes them. The files remain ordinary UTF-8 Markdown.

## Status

Early development. The current target is a usable macOS MVP with:

- native workspace navigation
- WYSIWYG Markdown editing
- tables with row and column controls
- live, atomic saving
- external-change detection and conflict protection
- Finder Quick Look previews
- undo/redo and standard formatting shortcuts
- no account, telemetry, cloud service, or network dependency at runtime

## Requirements

- Apple Silicon Mac
- macOS 14 or newer
- Xcode 26 or newer
- Node.js 22 or newer
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Build

```sh
./scripts/bootstrap.sh
open MarkdownViewer.xcodeproj
```

Run all automated checks with:

```sh
./scripts/test.sh
```

## Architecture

The macOS shell is SwiftUI/AppKit. A local `WKWebView` hosts the open-source Tiptap/ProseMirror editing engine. Swift owns filesystem access, workspace observation, atomic persistence, conflicts, native commands, and Quick Look. JavaScript assets are compiled into the app and no remote content is loaded.

See [docs/architecture.md](docs/architecture.md) for details.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).

