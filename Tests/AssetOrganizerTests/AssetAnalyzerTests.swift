import XCTest
@testable import AssetOrganizer

final class MockAssetRepository: AssetRepository {
    var mockAssets: [Asset] = []
    var mockUnusedAssets: [Asset] = []
    var deletedAssets: [Asset] = []
    
    func findAllAssets() async throws -> [Asset] {
        return mockAssets
    }
    
    func findUnusedAssets() async throws -> [Asset] {
        return mockUnusedAssets
    }
    
    func deleteAssets(_ assets: [Asset]) async throws {
        deletedAssets = assets
    }
    
    func analyzeAssetUsage(_ assets: [Asset]) async throws -> [Asset] {
        return assets.map { asset in
            var modifiedAsset = asset
            modifiedAsset.isUsed = !mockUnusedAssets.contains(where: { $0.path == asset.path })
            return modifiedAsset
        }
    }
}

final class AssetAnalyzerTests: XCTestCase {
    var mockRepository: MockAssetRepository!
    var analyzer: AssetAnalyzer!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAssetRepository()
        analyzer = AssetAnalyzer(repository: mockRepository)
    }
    
    func testAnalyzeAssets() async throws {
        // Given
        let asset1 = Asset(name: "image1.png", path: "/path/image1.png", type: .image, size: 1000, lastModified: Date())
        let asset2 = Asset(name: "image2.png", path: "/path/image2.png", type: .image, size: 2000, lastModified: Date())
        let asset3 = Asset(name: "image3.png", path: "/path/image3.png", type: .image, size: 3000, lastModified: Date())
        
        mockRepository.mockAssets = [asset1, asset2, asset3]
        mockRepository.mockUnusedAssets = [asset2, asset3]
        
        // When
        let report = try await analyzer.analyzeAssets()
        
        // Then
        XCTAssertEqual(report.totalAssets, 3)
        XCTAssertEqual(report.unusedAssets.count, 2)
        XCTAssertEqual(report.totalSize, 6000)
        XCTAssertEqual(report.unusedSize, 5000)
    }
    
    func testCleanUnusedAssets() async throws {
        // Given
        let asset1 = Asset(name: "image1.png", path: "/path/image1.png", type: .image, size: 1000, lastModified: Date())
        let asset2 = Asset(name: "image2.png", path: "/path/image2.png", type: .image, size: 2000, lastModified: Date())
        
        mockRepository.mockUnusedAssets = [asset1, asset2]
        
        // When
        try await analyzer.cleanUnusedAssets()
        
        // Then
        XCTAssertEqual(mockRepository.deletedAssets.count, 2)
        XCTAssertEqual(mockRepository.deletedAssets[0].path, asset1.path)
        XCTAssertEqual(mockRepository.deletedAssets[1].path, asset2.path)
    }
} 