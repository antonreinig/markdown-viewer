# Architecture

## Data flow

```text
Workspace sidebar -> DocumentSession -> Editor bridge -> Tiptap
                          |                  |
                          +---- Markdown ----+
                          |
                     atomic file writes
                          |
                  filesystem observation
```

`DocumentSession` owns the currently selected file and is the synchronization boundary. Editor transactions produce Markdown snapshots. A trailing 300 ms debounce keeps write amplification low, while a 1.5 second deadline guarantees that continuous typing still reaches disk. Writes use coordinated, atomic replacement.

Incoming filesystem events are compared with the last acknowledged disk snapshot. Clean documents reload immediately. Concurrent edits are merged when only one side changed; ambiguous overlapping changes are surfaced rather than overwritten.

## Editor boundary

The web editor is a bundled, offline resource. Messages crossing the bridge are deliberately small:

- `ready`
- `documentChanged(markdown)`
- `selectionChanged(state)`
- `openLink(url)`
- `loadMarkdown(markdown)`
- `perform(command)`

Swift does not depend on Tiptap's internal JSON schema. This keeps Markdown canonical and makes the editor replaceable.

## Quick Look

The Quick Look extension parses Markdown using Swift Markdown and returns sanitized HTML in a data-based preview reply. It shares no mutable state with the main application and makes no network requests.

