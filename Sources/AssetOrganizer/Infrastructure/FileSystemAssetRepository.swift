import Foundation

public final class FileSystemAssetRepository: AssetRepository {
    private let assetCatalogScanner: AssetCatalogScanning
    private let sourceCodeScanner: SourceCodeScanning
    private let fileManager: FileManager
    private let projectPath: String
    
    public init(
        projectPath: String,
        fileManager: FileManager = .default,
        includeSystemFiles: Bool = false
    ) {
        self.projectPath = projectPath
        self.fileManager = fileManager
        
        let fileScanner = FileScanner(fileManager: fileManager)
        let assetFactory = AssetFactory(fileManager: fileManager)
        let patternMatcher = PatternMatcher()
        
        self.assetCatalogScanner = AssetCatalogScanner(
            fileManager: fileManager,
            fileScanner: fileScanner,
            assetFactory: assetFactory,
            excludedDirectories: FileSystemConfiguration.excludedDirectories,
            includeSystemFiles: includeSystemFiles
        )
        
        self.sourceCodeScanner = SourceCodeScanner(
            fileManager: fileManager,
            fileScanner: fileScanner,
            patternMatcher: patternMatcher,
            excludedDirectories: FileSystemConfiguration.excludedDirectories,
            sourceCodeExtensions: FileSystemConfiguration.sourceCodeExtensions
        )
    }
    
    public func findAllAssets() async throws -> [Asset] {
        let catalogs = try assetCatalogScanner.findAssetCatalogs(in: projectPath)
        var allAssets: [Asset] = []
        
        for catalog in catalogs {
            let assets = try assetCatalogScanner.processAssetCatalog(catalog)
            allAssets.append(contentsOf: assets)
        }
        
        return allAssets
    }
    
    public func findUnusedAssets() async throws -> [Asset] {
        let assets = try await findAllAssets()
        return try await analyzeAssetUsage(assets).filter { !$0.isUsed }
    }
    
    public func deleteAssets(_ assets: [Asset]) async throws {
        for asset in assets {
            do {
                try deleteAsset(asset)
            } catch {
                throw AssetError.deletionFailed(asset.path)
            }
        }
    }
    
    public func analyzeAssetUsage(_ assets: [Asset]) async throws -> [Asset] {
        let sourceFiles = try sourceCodeScanner.findSourceFiles(in: projectPath)
        return try await sourceCodeScanner.analyzeAssetUsage(assets, in: sourceFiles)
    }
    
    private func deleteAsset(_ asset: Asset) throws {
        let assetURL = URL(fileURLWithPath: asset.path)
        let assetFolder = assetURL.deletingLastPathComponent()
        
        // Check if the folder is an asset folder (.imageset, .colorset, etc.)
        if assetFolder.lastPathComponent.contains(".imageset") ||
           assetFolder.lastPathComponent.contains(".colorset") ||
           assetFolder.lastPathComponent.contains(".dataset") {
            try fileManager.removeItem(at: assetFolder)
        } else {
            try fileManager.removeItem(at: assetURL)
        }
    }
} 