import SwiftUI

enum AppFont: String, CaseIterable, Identifiable {
    case monospaced = "SF Mono"
    case SFPro = "SF Pro"
    case courier = "Courier New"
    case jetbrains = "JetBrains Mono"
    
    var id: String { self.rawValue }
    
    var nsFontName: String {
        switch self {
        case .monospaced: return "NSFont.monospacedSystemFont"
        case .SFPro: return "NSFont.systemFont"
        case .courier: return "Courier"
        case .jetbrains: return "JetBrainsMono-Regular"
        }
    }
}

enum MenuBarIconChoice: String, CaseIterable, Identifiable {
    case pencilTip = "pencil.tip.crop.circle.fill"
    case pencil = "pencil"
    case note = "note.text"
    case document = "doc.text.fill"
    case terminal = "terminal.fill"
    case bubble = "text.bubble.fill"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .pencilTip: return "Default"
        case .pencil: return "Pencil"
        case .note: return "Note-Pad"
        case .document: return "Page"
        case .terminal: return "Terminal "
        case .bubble: return "Speech"
        }
    }
}

struct ThemeState {
    static let bgKey = "ThemeBGColor"
    static let textKey = "ThemeTextColor"
    static let arrowKey = "ThemeArrowColor"
    static let fontKey = "ThemeActiveFont"
    static let iconKey = "ThemeMenuIcon"
    
    static func getColor(for key: String, defaultColor: Color) -> Color {
        guard let hex = UserDefaults.standard.string(forKey: key) else { return defaultColor }
        return Color(hex: hex) ?? defaultColor
    }
    
    static func setColor(for key: String, color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.black
        if let components = nsColor.cgColor.components, components.count >= 3 {
            let r = Int(components[0].clamped(to: 0...1) * 255)
            let g = Int(components[1].clamped(to: 0...1) * 255)
            let b = Int(components[2].clamped(to: 0...1) * 255)
            let hex = String(format: "#%02X%02X%02X", r, g, b)
            UserDefaults.standard.set(hex, forKey: key)
            
            NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
        }
    }
}

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.max(Swift.min(self, range.upperBound), range.lowerBound)
    }
}

extension Color {
    init?(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") { cString.remove(at: cString.startIndex) }
        guard cString.count == 6 else { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        self.init(
            .sRGB,
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
}
