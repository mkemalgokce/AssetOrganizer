import Foundation
import Rainbow

public struct AssetAnalysisReport {
    public let totalAssets: Int
    public let unusedAssets: [Asset]
    public let totalSize: Int64
    public let unusedSize: Int64
    public let allAssets: [Asset]
    
    public func filtered(byType type: AssetType) -> AssetAnalysisReport {
        let filteredAssets = allAssets.filter { $0.type == type }
        let filteredUnused = unusedAssets.filter { $0.type == type }
        return AssetAnalysisReport(
            totalAssets: filteredAssets.count,
            unusedAssets: filteredUnused,
            totalSize: filteredAssets.reduce(0) { $0 + $1.size },
            unusedSize: filteredUnused.reduce(0) { $0 + $1.size },
            allAssets: filteredAssets
        )
    }
    
    public func filtered(byMinSize minSize: Int64) -> AssetAnalysisReport {
        let filteredAssets = allAssets.filter { $0.size >= minSize }
        let filteredUnused = unusedAssets.filter { $0.size >= minSize }
        return AssetAnalysisReport(
            totalAssets: filteredAssets.count,
            unusedAssets: filteredUnused,
            totalSize: filteredAssets.reduce(0) { $0 + $1.size },
            unusedSize: filteredUnused.reduce(0) { $0 + $1.size },
            allAssets: filteredAssets
        )
    }
    
    public func sorted(by sortOption: SortOption) -> AssetAnalysisReport {
        let sortedAssets = sortOption.sort(allAssets)
        let sortedUnused = sortOption.sort(unusedAssets)
        return AssetAnalysisReport(
            totalAssets: totalAssets,
            unusedAssets: sortedUnused,
            totalSize: totalSize,
            unusedSize: unusedSize,
            allAssets: sortedAssets
        )
    }
    
    public var jsonReport: String {
        return JSONReportGenerator().generateReport(from: self)
    }
    
    public var markdownReport: String {
        return MarkdownReportGenerator().generateReport(from: self)
    }
    
    public func formattedReport(showDetail: Bool) -> String {
        return ConsoleReportGenerator(showDetail: showDetail).generateReport(from: self)
    }
}

public actor AssetAnalyzer {
    private let repository: AssetRepository
    
    public init(repository: AssetRepository) {
        self.repository = repository
    }
    
    public func analyzeAssets() async throws -> AssetAnalysisReport {
        let allAssets = try await repository.findAllAssets()
        let analyzedAssets = try await repository.analyzeAssetUsage(allAssets)
        let unusedAssets = analyzedAssets.filter { !$0.isUsed }
        
        let totalSize = analyzedAssets.reduce(0) { $0 + $1.size }
        let unusedSize = unusedAssets.reduce(0) { $0 + $1.size }
        
        return AssetAnalysisReport(
            totalAssets: analyzedAssets.count,
            unusedAssets: unusedAssets,
            totalSize: totalSize,
            unusedSize: unusedSize,
            allAssets: analyzedAssets
        )
    }
    
    public func cleanUnusedAssets(matching type: AssetType? = nil) async throws {
        var unusedAssets = try await repository.findUnusedAssets()
        if let type = type {
            unusedAssets = unusedAssets.filter { $0.type == type }
        }
        try await repository.deleteAssets(unusedAssets)
    }
}