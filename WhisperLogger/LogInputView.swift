import SwiftUI
import AppKit

struct LogInputView: View {
    @EnvironmentObject private var logManager: LogManager
    @State private var currentInput: String = ""
    @State private var statusMessage: String = ""
    @State private var showStatus: Bool = false
    
    @State private var bgColor = ThemeState.getColor(for: ThemeState.bgKey, defaultColor: Color(.windowBackgroundColor).opacity(0.8))
    @State private var textColor = ThemeState.getColor(for: ThemeState.textKey, defaultColor: .primary)
    @State private var arrowColor = ThemeState.getColor(for: ThemeState.arrowKey, defaultColor: .secondary.opacity(0.6))
    
    private let fixedHeight: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Text(">>>")
                    .foregroundColor(arrowColor)
                    .font(getCustomFont())
                    .padding(.top, 1)
                
                CustomTextEditor(text: $currentInput, onSubmit: {
                    guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    logManager.saveEntry(currentInput)
                    currentInput = ""
                    showStatusMessage("Saved")
                }, onCommandShiftReturn: {
                    let trimmedInput = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    logManager.createNewLogFile(withInitialEntry: trimmedInput.isEmpty ? nil : currentInput)
                    
                    currentInput = ""
                    showStatusMessage(trimmedInput.isEmpty ? "New log file created" : "Saved to new log file")
                }, onEscape: {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                })
                .frame(height: fixedHeight)
                .id(UserDefaults.standard.string(forKey: ThemeState.fontKey)) // Force recreation if font changes
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            if showStatus && !statusMessage.isEmpty {
                HStack {
                    Text(statusMessage)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(textColor.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
        .frame(width: 400)
        .background(bgColor)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ThemeChanged"))) { _ in
            bgColor = ThemeState.getColor(for: ThemeState.bgKey, defaultColor: Color(.windowBackgroundColor).opacity(0.8))
            textColor = ThemeState.getColor(for: ThemeState.textKey, defaultColor: .primary)
            arrowColor = ThemeState.getColor(for: ThemeState.arrowKey, defaultColor: .secondary.opacity(0.6))
        }
    }
    
    private func getCustomFont() -> Font {
        let savedName = UserDefaults.standard.string(forKey: ThemeState.fontKey) ?? AppFont.monospaced.rawValue
        if savedName == AppFont.monospaced.rawValue {
            return .system(.body, design: .monospaced)
        }
        return .custom(savedName, size: NSFont.systemFontSize)
    }
    
    private func showStatusMessage(_ message: String) {
        statusMessage = message
        withAnimation { showStatus = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showStatus = false }
        }
    }
}

struct CustomTextEditor: NSViewRepresentable {
    @Binding var text: String
    let onSubmit: () -> Void
    let onCommandShiftReturn: () -> Void
    let onEscape: () -> Void
    
    class CustomTextView: NSTextView {
        var onSubmit: (() -> Void)?
        var onCommandShiftReturn: (() -> Void)?
        var onEscape: (() -> Void)?
        
        override func keyDown(with event: NSEvent) {
            if event.keyCode == 36 { // Return key
                if event.modifierFlags.contains([.command, .shift]) {
                    onCommandShiftReturn?()
                    return
                } else if event.modifierFlags.contains(.command) {
                    onSubmit?()
                    return
                }
            } else if event.keyCode == 53 { // Escape key
                onEscape?()
                return
            }
            super.keyDown(with: event)
        }
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        
        let contentSize = scrollView.contentSize
        let textView = CustomTextView(frame: NSRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height))
        
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        textView.textContainerInset = NSSize(width: 0, height: 0)
        
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isRichText = false
        
        textView.onSubmit = onSubmit
        textView.onCommandShiftReturn = onCommandShiftReturn
        textView.onEscape = onEscape
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            textView.string = text
        }
        
        let savedFontName = UserDefaults.standard.string(forKey: ThemeState.fontKey) ?? "SF Mono"
        if savedFontName == "SF Mono" {
            textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        } else {
            textView.font = NSFont(name: savedFontName, size: NSFont.systemFontSize) ?? .systemFont(ofSize: NSFont.systemFontSize)
        }
        textView.textColor = NSColor(ThemeState.getColor(for: ThemeState.textKey, defaultColor: .primary))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextEditor
        
        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
