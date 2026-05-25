import Foundation

struct TaskItem: Identifiable {
    let id = UUID()
    let text: String
    let filePath: URL
    let lineNumber: Int
    let dueDate: Date?
    let isToday: Bool
    let isDone: Bool

    var isDue: Bool {
        guard !isDone else { return false }
        if isToday { return true }
        guard let due = dueDate else { return false }
        let startOfTomorrow = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
        return due < startOfTomorrow
    }

    var dueDateDisplayString: String {
        if isToday && dueDate == nil { return "Due today" }
        guard let date = dueDate else { return "Due today" }
        if Calendar.current.isDateInToday(date) { return "Due today" }
        if Calendar.current.isDateInYesterday(date) { return "Was due yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Due \(formatter.string(from: date))"
    }
}
