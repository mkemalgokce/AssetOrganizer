import Foundation

protocol PatternMatching {
    func countMatches(pattern: String, in text: String) -> Int
}

final class PatternMatcher: PatternMatching {
    func countMatches(pattern: String, in text: String) -> Int {
        if pattern.hasPrefix("\\") {
            // Use regex for Swift symbol patterns
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            return regex.numberOfMatches(in: text, range: range)
        } else {
            // Use simple string matching for other patterns
            return text.components(separatedBy: pattern).count - 1
        }
    }
} 