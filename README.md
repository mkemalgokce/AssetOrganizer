# AssetOrganizer

A command-line tool for analyzing and managing unused assets in iOS/macOS projects. This tool helps you identify and clean up unused assets in your Xcode projects, reducing app size and maintaining a cleaner codebase.

## Features

- 🔍 Analyze asset usage in your project
- 📊 Generate detailed reports in multiple formats (Markdown, JSON, Console)
- 🎨 Support for various asset types:
  - Images (.png, .jpg, .jpeg, .gif, .pdf, .svg)
  - Colors (.colorset)
  - Data Sets (.dataset)
- 🗑 Clean up unused assets
- 💡 Smart asset detection and usage analysis
- 🛡 Safe deletion with confirmation prompts
- 📝 Detailed usage reporting showing where assets are used
- 🔄 Sort assets by name, size, or usage count
- ⚡️ Fast and efficient file scanning
- 🎯 Filter assets by type or minimum size

## Installation

### Using Swift Package Manager

```bash
git clone https://github.com/mkemalgokce/AssetOrganizer.git
cd AssetOrganizer
swift build -c release
sudo cp .build/release/AssetOrganizer /usr/local/bin/AssetOrganizer
```

## Usage

### Analyze Assets

To analyze assets in your project and generate a report:

```bash
AssetOrganizer analyze /path/to/your/project
```

#### Analysis Options

- `-d, --show-detail`: Show detailed information for each asset
- `-i, --include-system`: Include system files in the analysis
- `-t, --type <type>`: Filter assets by type (image, color, data)
- `-m, --min-size <size>`: Minimum size threshold (e.g., '100KB', '1MB')
- `-s, --sort-by <option>`: Sort assets by name, size, or usage
- `-o, --output <path>`: Save report to a file

#### Report Formats

The tool supports multiple report formats:

1. Markdown (default):
```bash
AssetOrganizer analyze /path/to/project -o report.md
# or simply
AssetOrganizer analyze /path/to/project -o report
```

2. JSON:
```bash
AssetOrganizer analyze /path/to/project -o report.json
```

3. Console Output (default if no output file specified):
```bash
AssetOrganizer analyze /path/to/project
```

### Clean Unused Assets

To remove unused assets from your project (including their containing folders like .imageset, .colorset, .dataset):

```bash
AssetOrganizer clean /path/to/your/project
```

#### Clean Options

- `-f, --force`: Skip confirmation before deleting
- `-n, --dry-run`: Perform a dry run without actually deleting files
- `-t, --type <type>`: Clean only specific asset types (image, color, data)
- `-m, --min-size <size>`: Clean only assets above specified size

> **Note**: When cleaning assets, the tool will remove the entire asset folder (e.g., image.imageset, color.colorset) to ensure a complete cleanup of unused resources.

## Examples

1. Analyze and show detailed report:
```bash
AssetOrganizer analyze /path/to/project -d
```

2. Find large unused images:
```bash
AssetOrganizer analyze /path/to/project -t image -m 1MB
```

3. Generate JSON report sorted by size:
```bash
AssetOrganizer analyze /path/to/project -s size -o report.json
```

4. Clean unused image assets:
```bash
AssetOrganizer clean /path/to/project -t image
```

5. Dry run cleaning:
```bash
AssetOrganizer clean /path/to/project -n
```

## Report Format

The analysis report includes:

- 📊 Summary statistics
  - Total number of assets
  - Number of unused assets
  - Total size
  - Size of unused assets
- 📋 Detailed asset information
  - Asset name and type
  - File size
  - Usage status
  - Usage count and locations
- ⚠️ Unused assets summary
  - File paths
  - Sizes
  - Asset types

## Development

### Requirements

- macOS 13.0 or later
- Swift 5.9 or later
- Xcode 15.0 or later


## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
