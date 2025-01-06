import ArgumentParser

public enum SortOption: String, ExpressibleByArgument {
    case name, size, usage
    
    public func sort(_ assets: [Asset]) -> [Asset] {
        switch self {
        case .name: return assets.sorted { $0.name < $1.name }
        case .size: return assets.sorted { $0.size > $1.size }
        case .usage: return assets.sorted { $0.totalUsageCount > $1.totalUsageCount }
        }
    }
} 