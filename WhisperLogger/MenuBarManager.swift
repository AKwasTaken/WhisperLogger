import SwiftUI
import AppKit
import KeyboardShortcuts

final class MenuBarManager: NSObject, NSWindowDelegate {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    
    private override init() {
        super.init()
        setupStatusItem()
        setupGlobalShortcutObserver()
    }
    
    private func setupGlobalShortcutObserver() {
        // Wraps the registration to safely satisfy MainActor isolation rules
        Task { @MainActor in
            KeyboardShortcuts.onKeyDown(for: .toggleWhisperLogger) { [weak self] in
                guard let self = self else { return }
                
                if let popover = self.popover, popover.isShown {
                    popover.performClose(nil)
                } else if let button = self.statusItem?.button {
                    self.showPopover(button)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        let savedIconName = UserDefaults.standard.string(forKey: ThemeState.iconKey) ?? "pencil.tip.crop.circle.fill"
        updateStatusBarIcon(named: savedIconName)
        
        if let button = statusItem?.button {
            button.target = self
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    func updateStatusBarIcon(named symbolName: String) {
        guard let button = statusItem?.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        
        if let icon = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Whisper Logger")?.withSymbolConfiguration(config) {
            icon.isTemplate = true
            button.image = icon
        }
    }
    
    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showContextMenu(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: NSStatusBarButton) {
        if let popover = popover, popover.isShown {
            popover.performClose(nil)
            return
        }
        
        let newPopover = NSPopover()
        newPopover.contentSize = NSSize(width: 400, height: 110)
        newPopover.behavior = .transient
        
        let hostingController = NSHostingController(
            rootView: PopoverContainerView().environmentObject(LogManager.shared)
        )
        newPopover.contentViewController = hostingController
        newPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        
        if let popoverWindow = hostingController.view.window {
            popoverWindow.backgroundColor = .clear
            popoverWindow.isOpaque = false
            
            if let frameView = popoverWindow.contentView?.superview {
                frameView.wantsLayer = true
                frameView.layer?.backgroundColor = .clear
            }
        }
        
        self.popover = newPopover
    }
    
    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Create New Log File", action: #selector(menuCreateFile), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show in Finder", action: #selector(menuShowInFinder), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(menuOpenSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit WhisperLogger", action: #selector(menuQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        for item in menu.items {
            if item.action != #selector(MenuBarManager.menuQuit) {
                item.target = self
            }
        }
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    // MARK: - Action Implementations
    @objc private func menuCreateFile() {
        LogManager.shared.createNewLogFile()
    }
    
    @objc private func menuShowInFinder() {
        let currentFile = LogManager.shared.currentLogFile
        let standardizedURL = URL(fileURLWithPath: currentFile.path)
        
        if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            if #available(macOS 14.0, *) {
                NSApp.yieldActivation(to: finderApp)
            }
            DispatchQueue.main.async {
                NSWorkspace.shared.activateFileViewerSelecting([standardizedURL])
                finderApp.activate(options: [])
            }
        } else {
            NSWorkspace.shared.selectFile(standardizedURL.path, inFileViewerRootedAtPath: "")
        }
    }
    
    @objc private func menuSelectDirectory() {
        LogManager.shared.selectLogsDirectory()
    }
    
    @objc func menuOpenSettings() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.settingsWindow == nil {
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 470, height: 500),
                    styleMask: [.titled, .closable],
                    backing: .buffered,
                    defer: false
                )
                window.center()
                window.title = "WhisperLogger Preferences"
                window.isReleasedWhenClosed = false
                window.delegate = self
                
                window.contentView = NSHostingView(
                    rootView: SettingsView().environmentObject(LogManager.shared)
                )
                self.settingsWindow = window
            }
            
            self.settingsWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
    
    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }
}
