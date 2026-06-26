import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // This creates a dedicated registration namespace for your global shortcut
    static let toggleWhisperLogger = Self("toggleWhisperLogger", initial: .init(.space, modifiers: [.option]))
}
