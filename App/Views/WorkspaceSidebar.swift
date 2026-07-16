import AppKit
import SwiftUI

struct WorkspaceSidebar: View {
    @EnvironmentObject private var workspace: WorkspaceStore

    var body: some View {
        VStack(spacing: 0) {
            if let root = workspace.rootURL {
                List(selection: selection) {
                    OutlineGroup(workspace.items, children: \.children) { item in
                        Label(item.name, systemImage: item.isDirectory ? "folder" : "doc.text")
                            .tag(item.isDirectory ? nil as URL? : item.url as URL?)
                            .help(item.url.path)
                            .accessibilityLabel(item.isDirectory ? "Folder \(item.name)" : "Markdown file \(item.name)")
                            .contextMenu {
                                Button("Rename…") { workspace.rename(item) }
                                Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
                                Divider()
                                Button("Move to Trash", role: .destructive) { workspace.moveToTrash(item) }
                            }
                    }
                }
                .listStyle(.sidebar)
                .safeAreaInset(edge: .top) {
                    HStack {
                        Image(systemName: "folder")
                        Text(root.lastPathComponent).font(.headline).lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.bar)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus").font(.system(size: 32)).foregroundStyle(.secondary)
                    Button("Open Folder…") { workspace.chooseWorkspace() }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Markdown File") { workspace.createFile() }
                    Button("New Folder") { workspace.createFolder() }
                } label: {
                    Label("New Item", systemImage: "plus")
                }
                .disabled(workspace.rootURL == nil)
            }
        }
    }

    private var selection: Binding<URL?> {
        Binding(get: { workspace.selectedFile }, set: { workspace.select($0) })
    }
}
