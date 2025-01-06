import Foundation

protocol SourceCodeScanning {
    func findSourceFiles(in projectPath: String) throws -> [URL]
    func analyzeAssetUsage(_ assets: [Asset], in sourceFiles: [URL]) async throws -> [Asset]
}

final class SourceCodeScanner: SourceCodeScanning {
    private let fileManager: FileManager
    private let fileScanner: FileScanning
    private let patternMatcher: PatternMatching
    private let excludedDirectories: Set<String>
    private let sourceCodeExtensions: Set<String>
    
    init(
        fileManager: FileManager = .default,
        fileScanner: FileScanning? = nil,
        patternMatcher: PatternMatching? = nil,
        excludedDirectories: Set<String>,
        sourceCodeExtensions: Set<String>
    ) {
        self.fileManager = fileManager
        self.fileScanner = fileScanner ?? FileScanner(fileManager: fileManager)
        self.patternMatcher = patternMatcher ?? PatternMatcher()
        self.excludedDirectories = excludedDirectories
        self.sourceCodeExtensions = sourceCodeExtensions
    }
    
    func findSourceFiles(in projectPath: String) throws -> [URL] {
        return try fileScanner.findFiles(
            in: projectPath,
            matching: { sourceCodeExtensions.contains($0.pathExtension) },
            excludedDirectories: excludedDirectories
        )
    }
    
    func analyzeAssetUsage(_ assets: [Asset], in sourceFiles: [URL]) async throws -> [Asset] {
        var modifiedAssets = assets
        
        for (index, asset) in assets.enumerated() {
            var usageDetails: [AssetUsage] = []
            let assetName = asset.name.replacingOccurrences(of: ".", with: "")
            
            for sourceFile in sourceFiles {
                let sourceContent = try String(contentsOf: sourceFile)
                var totalOccurrences = 0
                
                // Check for framework-specific usage patterns
                for pattern in asset.type.searchPatterns(for: assetName) {
                    totalOccurrences += patternMatcher.countMatches(pattern: pattern, in: sourceContent)
                }
                
                if totalOccurrences > 0 {
                    usageDetails.append(AssetUsage(
                        filePath: sourceFile.path,
                        occurrences: totalOccurrences
                    ))
                }
            }
            
            modifiedAssets[index].usageDetails = usageDetails
            modifiedAssets[index].isUsed = !usageDetails.isEmpty
        }
        
        return modifiedAssets
    }
} 