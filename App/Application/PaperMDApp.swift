import AppKit
import Sparkle
import SwiftUI

@main
struct PaperMDApp: App {
    @StateObject private var workspace = WorkspaceStore()
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(workspace)
                .frame(minWidth: 760, minHeight: 520)
                .onOpenURL { workspace.openDocument($0) }
                .task { workspace.restoreWorkspaceIfAvailable() }
        }
        .defaultSize(width: 1180, height: 760)
        .commands {
            WorkspaceCommands(workspace: workspace)
            EditorCommands()
            UpdateCommands(updater: updaterController.updater)
        }

        Settings {
            SettingsView()
        }
    }
}
