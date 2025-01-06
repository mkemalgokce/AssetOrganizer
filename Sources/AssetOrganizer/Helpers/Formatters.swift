import Foundation

enum Formatters {
    static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    static func formatBytes(_ bytes: Int64) -> String {
        return byteFormatter.string(fromByteCount: bytes)
    }
    
    static func parseSize(_ sizeStr: String) -> Int64? {
        let sizePattern = #/(\d+)\s*(KB|MB|GB|B)?/#
        guard let match = sizeStr.wholeMatch(of: sizePattern) else { return nil }
        
        let value = Int64(match.1) ?? 0
        let unit = match.2?.uppercased() ?? "B"
        
        switch unit {
        case "KB": return value * 1024
        case "MB": return value * 1024 * 1024
        case "GB": return value * 1024 * 1024 * 1024
        default: return value
        }
    }
} 