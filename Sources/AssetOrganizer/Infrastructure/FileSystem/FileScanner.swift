import Foundation

protocol FileScanning {
    func findFiles(
        in directory: String,
        matching predicate: (URL) -> Bool,
        excludedDirectories: Set<String>
    ) throws -> [URL]
}

final class FileScanner: FileScanning {
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func findFiles(
        in directory: String,
        matching predicate: (URL) -> Bool,
        excludedDirectories: Set<String>
    ) throws -> [URL] {
        let directoryURL = URL(fileURLWithPath: directory)
        var matchingFiles: [URL] = []
        
        if let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) {
            for case let fileURL as URL in enumerator {
                let path = fileURL.path
                if excludedDirectories.contains(where: { path.contains("/\($0)/") }) {
                    enumerator.skipDescendants()
                    continue
                }
                
                if predicate(fileURL) {
                    matchingFiles.append(fileURL)
                }
            }
        }
        
        return matchingFiles
    }
} 