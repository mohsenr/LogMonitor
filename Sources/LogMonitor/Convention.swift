import Foundation

public struct LogStorageConvention: Sendable {
    public enum BaseStorageLocation: Sendable {
        case appGroup(identifier: String)
    }
    
    public enum ExecutableTargetGroupingStrategy: Sendable {
        // There is no grouping. Each executable’s logs are stored separately.
        case none
    }
    
    public enum LogFileNamingStrategy: Sendable {
        case byBundleIdentifier(pathExtension: String)
    }
    
    /// Indicates where on the system the logs should be stored
    var baseStorageLocation: BaseStorageLocation
    
    /// Where would logs following this convention be stored
    var basePathComponents: [String]
    
    /// How logs from different executable targets are grouped
    ///
    /// A single conceptual “app” may have different excutables:
    /// - App extensions (such as widgets)
    /// - Embedded apps (for example for Watch OS)
    /// - Non-production variants
    ///
    /// This property indicates if there’s a strategy for grouping logs from these different executables
    var executableTargetGroupingStrategy: ExecutableTargetGroupingStrategy
    
    /// How is the log file for each executable named
    var executableTargetLogFileNamingStrategy: LogFileNamingStrategy
    
    public init(baseStorageLocation: BaseStorageLocation, basePathComponents: [String], executableTargetGroupingStrategy: ExecutableTargetGroupingStrategy, executableTargetLogFileNamingStrategy: LogFileNamingStrategy) {
        self.baseStorageLocation = baseStorageLocation
        self.basePathComponents = basePathComponents
        self.executableTargetGroupingStrategy = executableTargetGroupingStrategy
        self.executableTargetLogFileNamingStrategy = executableTargetLogFileNamingStrategy
    }
}

extension LogStorageConvention {
    public static let diagnosticsAppGroup = LogStorageConvention(
        baseStorageLocation: .appGroup(identifier: "group.diagnostics"),
        basePathComponents: ["Logs"],
        executableTargetGroupingStrategy: .none,
        executableTargetLogFileNamingStrategy: .byBundleIdentifier(pathExtension: "logs")
    )
}

public extension OSLogMonitor {
    
    init(convention: LogStorageConvention, appLaunchDate: Date = .now) throws {
        let fileManager = FileManager()
        
        let logFile = try fileManager.url(for: convention.baseStorageLocation)
            .appending(components: convention.basePathComponents)
            .appending(groupingComponentsFor: convention.executableTargetGroupingStrategy)
            .appending(logFilePathComponentsFor: convention.executableTargetLogFileNamingStrategy, bundleIdentifier: Bundle.main.bundleIdentifier!)
        
        let logDirectory = logFile.deletingLastPathComponent()
        try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        try self.init(url: logFile, appLaunchDate: appLaunchDate)
    }
    
}

private extension FileManager {
    
    func url(for storageLocation: LogStorageConvention.BaseStorageLocation) throws -> URL {
        switch storageLocation {
        case .appGroup(let identifier):
            guard let appGroupFolder = containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
                throw UndefinedAppGroup(identifier: identifier)
            }
            return appGroupFolder
        }
    }
    
}

private extension URL {
    
    func appending(components: [String]) -> URL {
        components.reduce(self) { $0.appending(component: $1, directoryHint: .isDirectory) }
    }
    
    func appending(groupingComponentsFor strategy: LogStorageConvention.ExecutableTargetGroupingStrategy) -> URL {
        switch strategy {
        case .none:
            self
        }
    }
    
    func appending(logFilePathComponentsFor strategy: LogStorageConvention.LogFileNamingStrategy, bundleIdentifier: String) -> URL {
        switch strategy {
        case .byBundleIdentifier(let pathExtension):
            appending(component: bundleIdentifier).appendingPathExtension("logs")
        }
    }
    
}

private struct UndefinedAppGroup: Error, Sendable {
    var identifier: String
}
