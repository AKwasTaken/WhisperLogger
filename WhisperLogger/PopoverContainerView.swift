import SwiftUI

struct PopoverContainerView: View {
    @EnvironmentObject private var logManager: LogManager
    
    var body: some View {
        VStack(spacing: 0) {
            LogInputView()
        }
        .background(.ultraThinMaterial)
        .background(
            Button(action: {
                NSWorkspace.shared.open(LogManager.shared.logsDirectory)
            }) {
                EmptyView()
            }
            .keyboardShortcut("o", modifiers: .command)
            .buttonStyle(.plain)
        )
        .background(
            Button(action: {
                NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                MenuBarManager.shared.menuOpenSettings()
            }) {
                EmptyView()
            }
            .keyboardShortcut(",", modifiers: .command)
            .buttonStyle(.plain)
        )
    }
}
