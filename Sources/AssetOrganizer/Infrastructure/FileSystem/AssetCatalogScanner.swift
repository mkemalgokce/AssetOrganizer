import Foundation

protocol AssetCatalogScanning {
    func findAssetCatalogs(in projectPath: String) throws -> [URL]
    func processAssetCatalog(_ catalogURL: URL) throws -> [Asset]
}

final class AssetCatalogScanner: AssetCatalogScanning {
    private let fileManager: FileManager
    private let fileScanner: FileScanning
    private let assetFactory: AssetCreating
    private let excludedDirectories: Set<String>
    private let includeSystemFiles: Bool
    
    init(
        fileManager: FileManager = .default,
        fileScanner: FileScanning? = nil,
        assetFactory: AssetCreating? = nil,
        excludedDirectories: Set<String>,
        includeSystemFiles: Bool
    ) {
        self.fileManager = fileManager
        self.fileScanner = fileScanner ?? FileScanner(fileManager: fileManager)
        self.assetFactory = assetFactory ?? AssetFactory(fileManager: fileManager)
        self.excludedDirectories = excludedDirectories
        self.includeSystemFiles = includeSystemFiles
    }
    
    func findAssetCatalogs(in projectPath: String) throws -> [URL] {
        return try fileScanner.findFiles(
            in: projectPath,
            matching: { $0.pathExtension == "xcassets" },
            excludedDirectories: excludedDirectories
        )
    }
    
    func processAssetCatalog(_ catalogURL: URL) throws -> [Asset] {
        var assets: [Asset] = []
        let contents = try fileManager.contentsOfDirectory(at: catalogURL, includingPropertiesForKeys: [.isDirectoryKey])
        
        for url in contents {
            let isDirectory = try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
            
            if isDirectory {
                if url.pathExtension == "imageset" {
                    try processImageSet(url, assets: &assets)
                } else if url.pathExtension == "colorset" {
                    try processColorSet(url, assets: &assets)
                } else if !url.pathExtension.isEmpty {
                    if let asset = try assetFactory.createAsset(from: url, overrideName: nil) {
                        assets.append(asset)
                    }
                } else {
                    let subAssets = try processAssetCatalog(url)
                    assets.append(contentsOf: subAssets)
                }
            }
        }
        
        return assets.filter { asset in
            if !includeSystemFiles {
                if asset.name.hasPrefix(".") || asset.name == "Contents" {
                    return false
                }
                if asset.path.contains("/.") {
                    return false
                }
            }
            return true
        }
    }
    
    private func processImageSet(_ imageSetURL: URL, assets: inout [Asset]) throws {
        let contents = try fileManager.contentsOfDirectory(at: imageSetURL, includingPropertiesForKeys: [.isRegularFileKey])
        let imageName = imageSetURL.deletingPathExtension().lastPathComponent
        
        let imageFiles = contents.filter { url in
            let isContentsJson = url.lastPathComponent == FileSystemConfiguration.assetContentFileName
            let isImageFile = AssetType.image.extensions.contains(url.pathExtension.lowercased())
            return !isContentsJson && isImageFile
        }
        
        for imageFile in imageFiles {
            if let asset = try assetFactory.createAsset(from: imageFile, overrideName: imageName) {
                assets.append(asset)
            }
        }
    }
    
    private func processColorSet(_ colorSetURL: URL, assets: inout [Asset]) throws {
        let contents = try fileManager.contentsOfDirectory(at: colorSetURL, includingPropertiesForKeys: [.isRegularFileKey])
        let colorName = colorSetURL.deletingPathExtension().lastPathComponent
        
        // Find Contents.json file
        if let contentsJson = contents.first(where: { $0.lastPathComponent == FileSystemConfiguration.assetContentFileName }) {
            if let asset = try assetFactory.createAsset(from: contentsJson, overrideName: colorName) {
                var modifiedAsset = asset
                modifiedAsset.type = .color  // Ensure type is set to color
                assets.append(modifiedAsset)
            }
        }
    }
} 