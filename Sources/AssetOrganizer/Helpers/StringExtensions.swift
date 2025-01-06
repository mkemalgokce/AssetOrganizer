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
}

enum StringStyle {
    case bold
    case colored(String)
} 