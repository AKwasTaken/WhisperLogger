import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var logManager: LogManager
    
    @State private var bgSelection = ThemeState.getColor(for: ThemeState.bgKey, defaultColor: Color(.windowBackgroundColor))
    @State private var textSelection = ThemeState.getColor(for: ThemeState.textKey, defaultColor: .primary)
    @State private var arrowSelection = ThemeState.getColor(for: ThemeState.arrowKey, defaultColor: .secondary)
    @State private var activeFont = AppFont(rawValue: UserDefaults.standard.string(forKey: ThemeState.fontKey) ?? "SF Mono") ?? .monospaced
    @State private var activeIcon = MenuBarIconChoice(rawValue: UserDefaults.standard.string(forKey: ThemeState.iconKey) ?? "pencil.tip.crop.circle.fill") ?? .pencilTip

    private let labelWidth: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            Text("WhisperLogger")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("v2.1.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer(minLength: 20)
            
            
            HStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 14) {
                    
                    // Row 1: Menu Bar Icon
                    HStack(spacing: 16) {
                        Text("Menu Bar Icon:")
                            .frame(width: labelWidth, alignment: .trailing)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $activeIcon) {
                            ForEach(MenuBarIconChoice.allCases) { choice in
                                HStack {
                                    Image(systemName: choice.rawValue)
                                    Text(choice.displayName)
                                }
                                .tag(choice)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 200, alignment: .leading)
                        .onChange(of: activeIcon) { _, val in
                            UserDefaults.standard.set(val.rawValue, forKey: ThemeState.iconKey)
                            MenuBarManager.shared.updateStatusBarIcon(named: val.rawValue)
                        }
                    }
                    
                    // Row 2: Editor Font
                    HStack(spacing: 16) {
                        Text("Editor Font:")
                            .frame(width: labelWidth, alignment: .trailing)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $activeFont) {
                            ForEach(AppFont.allCases) { font in
                                Text(font.rawValue)
                                    .tag(font)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180, alignment: .leading)
                        .onChange(of: activeFont) { _, newValue in
                            UserDefaults.standard.set(newValue.rawValue, forKey: ThemeState.fontKey)
                            NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
                        }
                    }
                    
                    // Row 3: Storage Path
                    HStack(spacing: 16) {
                        Text("Storage Path:")
                            .frame(width: labelWidth, alignment: .trailing)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Button("Browse...") { logManager.selectLogsDirectory() }
                                .buttonStyle(.bordered)
                        }
                    }
                    
                    // Row 4: File Prefix
                    HStack(spacing: 16) {
                        Text("File Prefix:")
                            .frame(width: labelWidth, alignment: .trailing)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 6) {
                            TextField("log", text: $logManager.customFilePrefix)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("_YYYY-MM-DD.txt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: labelWidth)
                    }
                    
                    
                    // Row 5: BG Tint
                    HStack(spacing: 16) {
                        Text("BG Tint:")
                            .frame(width: labelWidth, alignment: .trailing)
                            .foregroundColor(.secondary)
                        
                        ColorPicker("", selection: $bgSelection)
                            .labelsHidden()
                            .onChange(of: bgSelection) { _, val in ThemeState.setColor(for: ThemeState.bgKey, color: val) }
                    }
                    
                    // Row 6: Text Color
                    HStack(spacing: 16) {
                        Text("Text Color:")
                            .frame(width: labelWidth, alignment: .trailing)
                            .foregroundColor(.secondary)
                        
                        ColorPicker("", selection: $textSelection)
                            .labelsHidden()
                            .onChange(of: textSelection) { _, val in ThemeState.setColor(for: ThemeState.textKey, color: val) }
                    }
                    
                    // Row 7: Prompt Color
                    HStack(spacing: 16) {
                        Text("Prompt Color (>>>):")
                            .frame(width: labelWidth, alignment: .trailing)
                            .foregroundColor(.secondary)
                        
                        ColorPicker("", selection: $arrowSelection)
                            .labelsHidden()
                            .onChange(of: arrowSelection) { _, val in ThemeState.setColor(for: ThemeState.arrowKey, color: val) }
                    }
                        
                    HStack(spacing: 16) {
                        Button(action: {
                            if let url = URL(string: "https://github.com/akwastaken/WhisperLogger/issues") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Label("Report Bugs", systemImage: "ladybug")
                        }
                        .buttonStyle(.bordered)
                        .frame(width: labelWidth, alignment: .trailing)
                        
                        
                        Button(action: resetToSystemDefaults) {
                            Label("Reset Prefs", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: labelWidth, alignment: .leading)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                    
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.top, 20)
                .padding(.bottom, 20)
                
            VStack() {
                Text("Logging at: "+logManager.logsDirectory.path)
                .lineLimit(1)
                .foregroundColor(.secondary)
                .frame(alignment: .leading)
                
                Text("Created by Aneeth Kumaar, 2026.")
                .lineLimit(1)
                .foregroundColor(.secondary)
                .frame(alignment: .leading)

            }
            .font(.caption2)

        }
        .padding(30)
        .frame(width: 470)
        .background(Color(.windowBackgroundColor))
    }
    
    private func resetToSystemDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: ThemeState.bgKey)
        defaults.removeObject(forKey: ThemeState.textKey)
        defaults.removeObject(forKey: ThemeState.arrowKey)
        defaults.removeObject(forKey: ThemeState.fontKey)
        defaults.removeObject(forKey: ThemeState.iconKey)
        
        logManager.customFilePrefix = "log"
        
        bgSelection = Color(.windowBackgroundColor)
        textSelection = .primary
        arrowSelection = .secondary.opacity(0.6)
        activeFont = .monospaced
        activeIcon = .pencilTip
        
        defaults.set(activeIcon.rawValue, forKey: ThemeState.iconKey)
        defaults.set(activeFont.rawValue, forKey: ThemeState.fontKey)
        
        MenuBarManager.shared.updateStatusBarIcon(named: activeIcon.rawValue)
        NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
    }
}
