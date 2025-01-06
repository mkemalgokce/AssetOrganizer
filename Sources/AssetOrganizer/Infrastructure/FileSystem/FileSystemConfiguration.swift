import Foundation

struct FileSystemConfiguration {
    static let excludedDirectories: Set<String> = [
        "Pods",
        "Carthage",
        ".build",
        "build",
        "DerivedData"
    ]
    
    static let sourceCodeExtensions: Set<String> = [
        "swift",
        "m",
        "h",
        "mm",
        "cpp",
        "c",
        "hpp",
        "xib",
        "storyboard"
    ]
    
    static let assetContentFileName = "Contents.json"
} 