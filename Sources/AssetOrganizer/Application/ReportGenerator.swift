import Foundation

protocol ReportGenerator {
    func generateReport(from report: AssetAnalysisReport) -> String
}

struct MarkdownReportGenerator: ReportGenerator {
    func generateReport(from report: AssetAnalysisReport) -> String {
        var content = [
            "# Asset Analysis Report",
            "",
            "## 📊 Summary",
            "",
            "| Metric | Value |",
            "|--------|--------|",
            "| Total Assets | \(report.totalAssets) |",
            "| Unused Assets | \(report.unusedAssets.count) |",
            "| Total Size | \(Formatters.formatBytes(report.totalSize)) |",
            "| Size of Unused Assets | \(Formatters.formatBytes(report.unusedSize)) |",
            "",
            "## 📋 Asset Details",
            ""
        ]
        
        // Group assets by type
        let groupedAssets = Dictionary(grouping: report.allAssets) { $0.type }
        
        for (type, assets) in groupedAssets.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            content.append("### \(type.rawValue.capitalized) Assets")
            content.append("")
            
            if assets.isEmpty {
                content.append("No \(type.rawValue) assets found.")
                content.append("")
                continue
            }
            
            content.append(contentsOf: generateAssetTable(assets))
            content.append("")
            content.append(contentsOf: generateUsageDetails(assets.filter { $0.isUsed }))
        }
        
        if !report.unusedAssets.isEmpty {
            content.append(contentsOf: generateUnusedSummary(report.unusedAssets))
        }
        
        return content.joined(separator: "\n")
    }
    
    private func generateAssetTable(_ assets: [Asset]) -> [String] {
        var content = [
            "| Asset | Size | Status | Usage Count |",
            "|-------|------|--------|-------------|"
        ]
        
        for asset in assets {
            let status = asset.isUsed ? "✅ Used" : "❌ Unused"
            content.append("| \(asset.name) | \(Formatters.formatBytes(asset.size)) | \(status) | \(asset.totalUsageCount) |")
        }
        
        return content
    }
    
    private func generateUsageDetails(_ assets: [Asset]) -> [String] {
        guard !assets.isEmpty else { return [] }
        
        var content = ["#### Usage Details", ""]
        
        for asset in assets {
            content.append("<details>")
            content.append("<summary><b>\(asset.name)</b> (\(asset.totalUsageCount) occurrences)</summary>")
            content.append("")
            content.append("| File | Occurrences |")
            content.append("|------|-------------|")
            
            for usage in asset.usageDetails.sorted(by: { $0.occurrences > $1.occurrences }) {
                let relativePath = usage.filePath.replacingOccurrences(of: asset.path.components(separatedBy: "/").dropLast().joined(separator: "/"), with: "")
                content.append("| \(relativePath) | \(usage.occurrences) |")
            }
            
            content.append("")
            content.append("</details>")
            content.append("")
        }
        
        return content
    }
    
    private func generateUnusedSummary(_ assets: [Asset]) -> [String] {
        var content = [
            "## ⚠️ Unused Assets Summary",
            "",
            "| Asset | Size | Path |",
            "|-------|------|------|"
        ]
        
        for asset in assets {
            content.append("| \(asset.name) | \(Formatters.formatBytes(asset.size)) | \(asset.path) |")
        }
        
        return content
    }
}

struct ConsoleReportGenerator: ReportGenerator {
    let showDetail: Bool
    
    func generateReport(from report: AssetAnalysisReport) -> String {
        var content = [
            "Asset Analysis Report".style(.colored("cyan"), .bold),
            "==================".style(.colored("cyan")),
            "",
            "📊 Summary:".style(.colored("yellow"), .bold),
            "Total Assets: \(report.totalAssets)".style(.colored("green")),
            "Unused Assets: \(report.unusedAssets.count)".style(.colored("red")),
            "Total Size: \(Formatters.formatBytes(report.totalSize))".style(.colored("green")),
            "Size of Unused Assets: \(Formatters.formatBytes(report.unusedSize))".style(.colored("red")),
            "",
            "📋 Asset Details:".style(.colored("yellow"), .bold),
            ""
        ]
        
        // Group assets by type
        let groupedAssets = Dictionary(grouping: report.allAssets) { $0.type }
        
        for (type, assets) in groupedAssets.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            content.append("[\(type.rawValue.capitalized) Assets]".style(.colored("yellow")))
            
            for asset in assets {
                let color = asset.isUsed ? "green" : "red"
                let usageStatus = asset.isUsed ? "Used (\(asset.totalUsageCount) times)" : "Unused"
                
                content.append("- \(asset.name) (\(Formatters.formatBytes(asset.size)))".style(.colored(color)))
                
                if showDetail {
                    content.append("  Path: \(asset.path)".style(.colored("lightBlack")))
                    content.append("  Status: \(usageStatus)".style(.colored(color)))
                    
                    if asset.isUsed {
                        content.append("  Used in:".style(.colored("lightBlack")))
                        for usage in asset.usageDetails.sorted(by: { $0.occurrences > $1.occurrences }) {
                            content.append("    • \(usage.filePath) (\(usage.occurrences) occurrences)".style(.colored("green")))
                        }
                    }
                    content.append("")
                }
            }
        }
        
        if report.unusedAssets.isEmpty {
            content.append("\nNo unused assets found! 🎉".style(.colored("green")))
        } else {
            content.append("\n⚠️  Unused Assets Summary:".style(.colored("yellow"), .bold))
            for asset in report.unusedAssets {
                content.append("- \(asset.name) (\(Formatters.formatBytes(asset.size)))".style(.colored("red")))
                if showDetail {
                    content.append("  Path: \(asset.path)".style(.colored("lightBlack")))
                }
            }
        }
        
        return content.joined(separator: "\n")
    }
}

struct JSONReportGenerator: ReportGenerator {
    func generateReport(from report: AssetAnalysisReport) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonReport = JSONReport(
            summary: .init(
                totalAssets: report.totalAssets,
                unusedAssets: report.unusedAssets.count,
                totalSize: report.totalSize,
                unusedSize: report.unusedSize
            ),
            assets: report.allAssets.map(JSONAsset.init)
        )
        
        guard let data = try? encoder.encode(jsonReport),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        
        return json
    }
    
    private struct JSONReport: Encodable {
        let summary: Summary
        let assets: [JSONAsset]
        
        struct Summary: Encodable {
            let totalAssets: Int
            let unusedAssets: Int
            let totalSize: Int64
            let unusedSize: Int64
        }
    }
    
    private struct JSONAsset: Encodable {
        let name: String
        let path: String
        let type: String
        let size: Int64
        let isUsed: Bool
        let usageCount: Int
        let usageDetails: [JSONUsage]
        
        struct JSONUsage: Encodable {
            let file: String
            let occurrences: Int
        }
        
        init(from asset: Asset) {
            self.name = asset.name
            self.path = asset.path
            self.type = asset.type.rawValue
            self.size = asset.size
            self.isUsed = asset.isUsed
            self.usageCount = asset.totalUsageCount
            self.usageDetails = asset.usageDetails.map { usage in
                JSONUsage(file: usage.filePath, occurrences: usage.occurrences)
            }
        }
    }
} 