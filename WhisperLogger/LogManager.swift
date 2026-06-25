import Foundation
import AppKit

final class LogManager: ObservableObject {
    static let shared = LogManager()
    
    // MARK: - Published Trackers
    @Published private(set) var logFiles: [URL] = []
    @Published private(set) var currentLogFile: URL
    @Published private(set) var logsDirectory: URL
    @Published private(set) var isUsingDefaultLocation: Bool = false
    
    // MARK: - Core Preference Bindings
    @Published var use24HourFormat: Bool {
        didSet { defaults.set(use24HourFormat, forKey: use24HourKey); updateDateFormat() }
    }
    @Published var customPrefix: String {
        didSet { defaults.set(customPrefix, forKey: prefixKey) }
    }
    @Published var doubleLineSpacing: Bool {
        didSet { defaults.set(doubleLineSpacing, forKey: lineSpacingKey) }
    }
    @Published var customFilePrefix: String {
        didSet { defaults.set(customFilePrefix, forKey: filePrefixKey) }
    }
    
    // MARK: - Private Core Storage
    private let fileManager = FileManager.default
    private let dateFormatter = DateFormatter()
    private let defaults = UserDefaults.standard
    
    // Keys Storage
    private let lastDirectoryKey = "LastSelectedLogsDirectory"
    private let currentFileKey = "CurrentLogFile"
    private let use24HourKey = "PrefsUse24HourFormat"
    private let prefixKey = "PrefsCustomPrefix"
    private let lineSpacingKey = "PrefsDoubleLineSpacing"
    private let filePrefixKey = "PrefsCustomFilePrefix"
    
    private init() {
        // 1. Decoupled local defaults generation
        let rawUse24Hour = UserDefaults.standard.object(forKey: use24HourKey) as? Bool ?? false
        let rawPrefix = UserDefaults.standard.string(forKey: prefixKey) ?? "[timestamp]"
        let rawLineSpacing = UserDefaults.standard.object(forKey: lineSpacingKey) as? Bool ?? false
        let rawFilePrefix = UserDefaults.standard.string(forKey: filePrefixKey) ?? "log"
        
        // --- UPDATED BLOCK HERE ---
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let defaultURL = documentsURL.appendingPathComponent("WhisperLogger_Logs", isDirectory: true)
        // --------------------------
        
        let resolvedDirectory: URL
        if let savedPath = UserDefaults.standard.string(forKey: lastDirectoryKey),
           let savedURL = URL(string: savedPath),
           fileManager.fileExists(atPath: savedURL.path) {
            resolvedDirectory = savedURL
        } else {
            resolvedDirectory = defaultURL
        }
    
        let tempFormatter = DateFormatter()
        tempFormatter.dateFormat = rawUse24Hour ? "yyyy-MM-dd_HH-mm-ss" : "yyyy-MM-dd_hh-mm-ss-a"
        
        let resolvedFile: URL
        if let savedFile = UserDefaults.standard.string(forKey: currentFileKey).map({ URL(fileURLWithPath: $0) }),
           fileManager.fileExists(atPath: savedFile.path) {
            resolvedFile = savedFile
        } else {
            let timestamp = tempFormatter.string(from: Date())
            resolvedFile = resolvedDirectory.appendingPathComponent("\(rawFilePrefix)_\(timestamp).txt")
        }
        
        // 2. Complete Phase-1 Allocations
        self.logsDirectory = resolvedDirectory
        self.currentLogFile = resolvedFile
        self.isUsingDefaultLocation = (resolvedDirectory == defaultURL)
        self.use24HourFormat = rawUse24Hour
        self.customPrefix = rawPrefix
        self.doubleLineSpacing = rawLineSpacing
        self.customFilePrefix = rawFilePrefix
        
        // 3. Launch Core Directories
        try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        updateDateFormat()
        refreshLogFiles()
    }
    
    private func updateDateFormat() {
        dateFormatter.dateFormat = use24HourFormat ? "yyyy-MM-dd HH:mm:ss" : "yyyy-MM-dd hh:mm:ss a"
    }
    
    // MARK: - File Writing Operations
    func saveEntry(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let formattedPrefix = customPrefix.replacingOccurrences(of: "timestamp", with: timestamp)
        let lineEnding = doubleLineSpacing ? "\n\n" : "\n"
        let entry = "\(formattedPrefix) \(trimmed)\(lineEnding)"
        
        // Move entirely to system userInitiated threads
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let data = entry.data(using: .utf8) else { return }
            
            if !self.fileManager.fileExists(atPath: self.currentLogFile.path) {
                try? entry.write(to: self.currentLogFile, atomically: true, encoding: .utf8)
            } else if let handle = try? FileHandle(forWritingTo: self.currentLogFile) {
                // Modern swift secure write block pipeline
                do {
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                    try handle.close()
                } catch {
                    try? handle.close()
                }
            }
            self.refreshLogFiles()
        }
    }
    
    func createNewLogFile(withInitialEntry entryText: String? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = use24HourFormat ? "yyyy-MM-dd_HH-mm-ss" : "yyyy-MM-dd_hh-mm-ss-a"
        
        currentLogFile = logsDirectory.appendingPathComponent("\(customFilePrefix)_\(formatter.string(from: Date())).txt")
        defaults.set(currentLogFile.path, forKey: currentFileKey)
        
        if let initialText = entryText {
            saveEntry(initialText)
        } else {
            refreshLogFiles()
        }
    }
    
    func selectLogsDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = logsDirectory
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        self.logsDirectory = url
        self.isUsingDefaultLocation = false
        self.defaults.set(url.absoluteString, forKey: self.lastDirectoryKey)
        createNewLogFile()
    }
    
    func refreshLogFiles() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let files = try? self.fileManager.contentsOfDirectory(at: self.logsDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
            
            let sortedFiles = files
                .filter { $0.pathExtension == "txt" }
                .sorted { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    return date1 > date2
                }
            
            DispatchQueue.main.async { self.logFiles = sortedFiles }
        }
    }
}
