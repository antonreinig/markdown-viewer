import SwiftUI

struct EditorToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            Button { performEditorCommand(.bold) } label: { Label("Bold", systemImage: "bold") }
                .help("Bold (⌘B)")
            Button { performEditorCommand(.italic) } label: { Label("Italic", systemImage: "italic") }
                .help("Italic (⌘I)")
            Menu {
                Button("Paragraph") { performEditorCommand(.paragraph) }
                Button("Heading 1") { performEditorCommand(.heading1) }
                Button("Heading 2") { performEditorCommand(.heading2) }
                Button("Heading 3") { performEditorCommand(.heading3) }
            } label: {
                Label("Text Style", systemImage: "textformat")
            }
            Menu {
                Button("Bulleted List") { performEditorCommand(.bulletList) }
                Button("Numbered List") { performEditorCommand(.orderedList) }
                Button("Task List") { performEditorCommand(.taskList) }
                Divider()
                Button("Block Quote") { performEditorCommand(.blockquote) }
                Button("Code Block") { performEditorCommand(.codeBlock) }
            } label: {
                Label("Lists and Blocks", systemImage: "list.bullet")
            }
            TableMenu()
        }
    }
}

private struct TableMenu: View {
    var body: some View {
        Menu {
            Button("Insert Table") { performEditorCommand(.insertTable) }
            Divider()
            Button("Add Row Above") { performEditorCommand(.addRowBefore) }
            Button("Add Row Below") { performEditorCommand(.addRowAfter) }
            Button("Delete Row") { performEditorCommand(.deleteRow) }
            Divider()
            Button("Add Column Before") { performEditorCommand(.addColumnBefore) }
            Button("Add Column After") { performEditorCommand(.addColumnAfter) }
            Button("Delete Column") { performEditorCommand(.deleteColumn) }
            Divider()
            Button("Toggle Header Row") { performEditorCommand(.toggleHeaderRow) }
            Button("Delete Table", role: .destructive) { performEditorCommand(.deleteTable) }
        } label: {
            Label("Table", systemImage: "tablecells")
        }
    }
}

