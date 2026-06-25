import SwiftUI

@main
struct WhisperLoggerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        CustomHeadlessScene()
    }
}

struct CustomHeadlessScene: Scene {
    var body: some Scene {
        #if os(macOS)
        Settings {
            EmptyView()
        }
        #else
        WindowGroup {
            EmptyView()
        }
        #endif
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        for window in NSApp.windows {
            if window.title != "WhisperLogger Preferences" {
                window.close()
            }
        }
        
        _ = LogManager.shared
        _ = MenuBarManager.shared
    }
}
