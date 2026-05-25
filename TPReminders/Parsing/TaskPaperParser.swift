import Foundation

enum TaskPaperParser {
    static func parse(fileURL: URL) -> [TaskItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let content = try? String(contentsOf: fileURL, encoding: .utf8)
        else { return [] }

        var tasks: [TaskItem] = []
        let lines = content.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            guard isTaskLine(line) else { continue }
            let body = taskBody(from: line)
            let tags = extractTags(from: body)
            let isDone = tags["done"] != nil
            let isToday = tags["today"] != nil
            let dueDate = tags["due"].flatMap { parseDueDate($0) }

            tasks.append(TaskItem(
                text: stripTags(from: body),
                filePath: fileURL,
                lineNumber: index + 1,
                dueDate: dueDate,
                isToday: isToday,
                isDone: isDone
            ))
        }
        return tasks
    }

    // Lines that start with optional whitespace then "- "
    private static func isTaskLine(_ line: String) -> Bool {
        let trimmed = line.drop(while: { $0 == "\t" || $0 == " " })
        return trimmed.hasPrefix("- ")
    }

    private static func taskBody(from line: String) -> String {
        let trimmed = line.drop(while: { $0 == "\t" || $0 == " " })
        return trimmed.hasPrefix("- ") ? String(trimmed.dropFirst(2)) : String(trimmed)
    }

    // Returns tag name → value (empty string for bare tags like @today)
    private static func extractTags(from text: String) -> [String: String] {
        let pattern = "@(\\w+)(?:\\(([^)]*)\\))?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [:] }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        var result: [String: String] = [:]
        for match in matches {
            let name = nsText.substring(with: match.range(at: 1)).lowercased()
            let value = match.range(at: 2).location != NSNotFound
                ? nsText.substring(with: match.range(at: 2))
                : ""
            result[name] = value
        }
        return result
    }

    private static func stripTags(from text: String) -> String {
        let pattern = "@\\w+(?:\\([^)]*\\))?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private static func parseDueDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        let formats = ["yyyy-MM-dd HH:mm", "yyyy-MM-dd"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: trimmed) { return date }
        }
        return nil
    }
}
