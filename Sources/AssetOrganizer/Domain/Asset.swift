import Foundation
import ArgumentParser

public struct AssetUsage: Hashable, Codable {
    public let filePath: String
    public let occurrences: Int
}

public struct Asset: Hashable, Codable {
    public let name: String
    public let path: String
    public var type: AssetType
    public let size: Int64
    public let lastModified: Date
    public var isUsed: Bool
    public var usageDetails: [AssetUsage]
    
    public init(name: String, path: String, type: AssetType, size: Int64, lastModified: Date, isUsed: Bool = false, usageDetails: [AssetUsage] = []) {
        self.name = name
        self.path = path
        self.type = type
        self.size = size
        self.lastModified = lastModified
        self.isUsed = isUsed
        self.usageDetails = usageDetails
    }
    
    public var totalUsageCount: Int {
        usageDetails.reduce(0) { $0 + $1.occurrences }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path) // Using path as it's unique
    }
    
    public static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.path == rhs.path // Using path as the unique identifier
    }
}

public enum AssetType: String, CaseIterable, ExpressibleByArgument, Codable {
    case image
    case color
    case data
    
    public init?(argument: String) {
        self.init(rawValue: argument.lowercased())
    }
    
    public var extensions: [String] {
        switch self {
        case .image:
            return ["png", "jpg", "jpeg", "gif", "pdf", "svg", "imageset"]
        case .color:
            return ["colorset"]
        case .data:
            return ["json", "dataset"]
        }
    }
    
    public func searchPatterns(for assetName: String) -> [String] {
        let symbolName = assetName.convertToCamelCase()
        
        switch self {
        case .image:
            return [
                // Swift Asset Symbols (SwiftUI)
                "\\.\(symbolName)(?![A-Za-z0-9])",  // .imageName
                "Image\\.\(symbolName)(?![A-Za-z0-9])",  // Image.imageName
                // Swift Asset Symbols (UIKit)
                "UIImage\\.\(symbolName)(?![A-Za-z0-9])",  // UIImage.imageName
                // Traditional UIKit
                "UIImage(named: \"\(assetName)\")",
                "UIImage(named:\"\(assetName)\")",
                "[UIImage imageNamed:\"\(assetName)\"]",
                "imageNamed:\"\(assetName)\"",
                // SwiftUI
                "Image(\"\(assetName)\")",
                "Image(\"",
                // AppKit
                "NSImage(named: \"\(assetName)\")",
                "NSImage(named:\"\(assetName)\")",
                // Asset Catalog
                "\"\(assetName)\"",
                "named: \"\(assetName)\"",
                // Storyboard/XIB
                "image=\"\(assetName)\"",
                "image = \"\(assetName)\""
            ]
        case .color:
            return [
                // Swift Asset Symbols (SwiftUI)
                "\\.\(symbolName)(?![A-Za-z0-9])",  // .colorName
                "Color\\.\(symbolName)(?![A-Za-z0-9])",  // Color.colorName
                // Swift Asset Symbols (UIKit)
                "UIColor\\.\(symbolName)(?![A-Za-z0-9])",  // UIColor.colorName
                // Traditional UIKit
                "UIColor(named: \"\(assetName)\")",
                "UIColor(named:\"\(assetName)\")",
                "[UIColor colorNamed:\"\(assetName)\"]",
                "colorNamed:\"\(assetName)\"",
                // SwiftUI
                "Color(\"\(assetName)\")",
                "Color(\"",
                // AppKit
                "NSColor(named: \"\(assetName)\")",
                "NSColor(named:\"\(assetName)\")",
                "NSColor\\.\(symbolName)(?![A-Za-z0-9])",  // NSColor.colorName
                // Asset Catalog
                "\"\(assetName)\"",
                "named: \"\(assetName)\"",
                // Storyboard/XIB
                "color=\"\(assetName)\"",
                "color = \"\(assetName)\"",
                "backgroundColor=\"\(assetName)\"",
                "backgroundColor = \"\(assetName)\"",
                "textColor=\"\(assetName)\"",
                "textColor = \"\(assetName)\"",
                "tintColor=\"\(assetName)\"",
                "tintColor = \"\(assetName)\""
            ]
        case .data:
            return ["\"\(assetName)\""]
        }
    }
} 