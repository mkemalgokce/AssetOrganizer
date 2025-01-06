import Foundation

protocol AssetCreating {
    func createAsset(from url: URL, overrideName: String?) throws -> Asset?
    func determineAssetType(from url: URL) -> AssetType
}

final class AssetFactory: AssetCreating {
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func createAsset(from url: URL, overrideName: String? = nil) throws -> Asset? {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        guard let fileSize = resourceValues.fileSize,
              let modificationDate = resourceValues.contentModificationDate else {
            return nil
        }
        
        let assetType = determineAssetType(from: url)
        let name = overrideName ?? url.deletingPathExtension().lastPathComponent
        
        var totalSize = Int64(fileSize)
        if assetType == .color {
            let parentURL = url.deletingLastPathComponent()
            if parentURL.pathExtension == "colorset" {
                let contents = try fileManager.contentsOfDirectory(at: parentURL, includingPropertiesForKeys: [.fileSizeKey])
                totalSize = contents.reduce(Int64(0)) { total, fileURL in
                    if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        return total + Int64(size)
                    }
                    return total
                }
            }
        }
        
        return Asset(
            name: name,
            path: url.path,
            type: assetType,
            size: totalSize,
            lastModified: modificationDate
        )
    }
    
    func determineAssetType(from url: URL) -> AssetType {
        let fileExtension = url.pathExtension.lowercased()
        let parentExtension = url.deletingLastPathComponent().pathExtension.lowercased()
        
        if url.path.contains(".imageset/") || parentExtension == "imageset" {
            return .image
        } else if url.path.contains(".colorset/") || parentExtension == "colorset" {
            return .color
        }
        
        for type in AssetType.allCases {
            if type.extensions.contains(fileExtension) {
                return type
            }
        }
        
        return .data
    }
} 