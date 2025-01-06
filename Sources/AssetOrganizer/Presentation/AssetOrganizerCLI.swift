import Foundation
import ArgumentParser
import Rainbow

@main
struct AssetOrganizerCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "asset-organizer",
        abstract: "A tool for analyzing and managing unused assets in your iOS/macOS project.",
        discussion: """
            Asset Organizer helps you maintain a clean asset catalog by identifying unused assets
            and providing detailed usage analysis. It supports various asset types including
            images, colors, and data sets.
            """,
        subcommands: [Analyze.self, Clean.self],
        defaultSubcommand: Analyze.self
    )
}

// MARK: - Common Options
extension AssetOrganizerCLI {
    struct CommonOptions: ParsableArguments {
        @Argument(help: "Path to the project directory")
        var projectPath: String
        
        @Flag(name: [.customShort("d"), .long], help: "Show detailed information for each asset")
        var showDetail = false
        
        @Flag(name: [.customShort("i"), .long], help: "Include system files in the analysis")
        var includeSystem = false
        
        @Option(name: [.customShort("t"), .long], help: "Filter assets by type (image, color, data)")
        var type: AssetType?
        
        @Option(name: [.customShort("m"), .long], help: "Minimum size threshold for reporting (e.g., '100KB', '1MB')")
        var minSize: String?
        
        var minSizeBytes: Int64? {
            guard let sizeStr = minSize else { return nil }
            return Formatters.parseSize(sizeStr)
        }
        
        init() {}
    }
}

// MARK: - Analyze Command
extension AssetOrganizerCLI {
    struct Analyze: AsyncParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "analyze",
            abstract: "Analyze assets in the project directory"
        )
        
        @OptionGroup var options: CommonOptions
        
        @Option(name: [.customShort("o"), .long], help: "Output file path for the report (defaults to markdown, use .json extension for JSON format)")
        var outputPath: String?
        
        @Option(name: [.customShort("s"), .long], help: "Sort assets by: name, size, or usage")
        var sortBy: SortOption?
        
        mutating func run() async throws {
            print("🔍 Analyzing assets...".style(.colored("yellow")))
            
            let repository = FileSystemAssetRepository(
                projectPath: options.projectPath,
                includeSystemFiles: options.includeSystem
            )
            
            let analyzer = AssetAnalyzer(repository: repository)
            var report = try await analyzer.analyzeAssets()
            
            if let type = options.type {
                report = report.filtered(byType: type)
            }
            
            if let minSize = options.minSizeBytes {
                report = report.filtered(byMinSize: minSize)
            }
            
            if let sortOption = sortBy {
                report = report.sorted(by: sortOption)
            }
            
            if let outputPath = outputPath {
                let adjustedPath: String
                let isJson = outputPath.lowercased().hasSuffix(".json")
                let isMd = outputPath.lowercased().hasSuffix(".md")
                
                if !outputPath.contains(".") {
                    // No extension provided, add .md
                    adjustedPath = outputPath + ".md"
                } else if isJson || isMd {
                    // Keep existing extension if it's .json or .md
                    adjustedPath = outputPath
                } else {
                    // Replace other extensions with .md
                    let withoutExtension = outputPath.components(separatedBy: ".").dropLast().joined(separator: ".")
                    adjustedPath = withoutExtension + ".md"
                }
                
                let content = isJson ? report.jsonReport : report.markdownReport
                try content.write(toFile: adjustedPath, atomically: true, encoding: .utf8)
                print("✅ Report saved to: \(adjustedPath)".style(.colored("green")))
            } else {
                print(report.formattedReport(showDetail: options.showDetail))
            }
        }
    }
}

// MARK: - Clean Command
extension AssetOrganizerCLI {
    struct Clean: AsyncParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "clean",
            abstract: "Remove unused assets from the project"
        )
        
        @OptionGroup var options: CommonOptions
        
        @Flag(name: [.customShort("f"), .long], help: "Skip confirmation before deleting")
        var force = false
        
        @Flag(name: [.customShort("n"), .long], help: "Perform a dry run without actually deleting files")
        var dryRun = false
        
        func run() async throws {
            let repository = FileSystemAssetRepository(
                projectPath: options.projectPath,
                includeSystemFiles: options.includeSystem
            )
            let analyzer = AssetAnalyzer(repository: repository)
            
            print("🔍 Analyzing assets...".style(.colored("yellow")))
            var report = try await analyzer.analyzeAssets()
            
            // Apply filters
            if let type = options.type {
                report = report.filtered(byType: type)
            }
            if let minSize = options.minSizeBytes {
                report = report.filtered(byMinSize: minSize)
            }
            
            guard !report.unusedAssets.isEmpty else {
                print("\nNo unused assets to clean! 🎉".style(.colored("green")))
                return
            }
            
            print(report.formattedReport(showDetail: options.showDetail))
            
            if dryRun {
                print("\n🔍 Dry run completed. No files were deleted.".style(.colored("yellow")))
                return
            }
            
            if !force {
                print("\n⚠️  Warning: This will permanently delete the unused assets listed above.".style(.colored("yellow"), .bold))
                print("Do you want to continue? [y/N]".style(.colored("yellow")))
                
                guard let response = readLine()?.lowercased(),
                      response == "y" || response == "yes" else {
                    print("Operation cancelled.".style(.colored("red")))
                    return
                }
            }
            
            print("\n🗑  Cleaning unused assets...".style(.colored("yellow")))
            try await analyzer.cleanUnusedAssets(matching: options.type)
            print("✅ Unused assets have been removed successfully!".style(.colored("green"), .bold))
        }
    }
} 