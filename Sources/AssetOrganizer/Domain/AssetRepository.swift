import Foundation

public protocol AssetRepository {
    func findAllAssets() async throws -> [Asset]
    func findUnusedAssets() async throws -> [Asset]
    func deleteAssets(_ assets: [Asset]) async throws
    func analyzeAssetUsage(_ assets: [Asset]) async throws -> [Asset]
}

public enum AssetError: LocalizedError {
    case fileNotFound(String)
    case invalidPath(String)
    case accessDenied(String)
    case deletionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        case .accessDenied(let path):
            return "Access denied to path: \(path)"
        case .deletionFailed(let path):
            return "Failed to delete asset at path: \(path)"
        }
    }
} 