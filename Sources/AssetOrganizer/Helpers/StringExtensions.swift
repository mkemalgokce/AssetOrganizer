import Foundation
import Rainbow

extension String {
    func applyingColor(_ color: String) -> String {
        switch color {
        case "red": return self.red
        case "green": return self.green
        case "yellow": return self.yellow
        case "cyan": return self.cyan
        case "lightBlack": return self.lightBlack
        default: return self
        }
    }
    
    func style(_ styles: StringStyle...) -> String {
        var result = self
        for style in styles {
            switch style {
            case .bold: result = result.bold
            case .colored(let color): result = result.applyingColor(color)
            }
        }
        return result
    }

    func convertToCamelCase() -> String {
        if self.contains(where: { $0.isUppercase }) && !self.contains(" ") && !self.contains("-") && !self.contains("_") {
            return self.prefix(1).lowercased() + self.dropFirst()
        }
        
        let normalized = self.replacingOccurrences(of: "[-_]", with: " ", options: .regularExpression)
        
        let words = normalized.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, word in
                if index == 0 {
                    return word.lowercased()
                }
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
        
        return words.joined()
    }

    
}

enum StringStyle {
    case bold
    case colored(String)
} 