import AppKit
import UserNotifications

private let kFilePathUserInfoKey = "filePath"

class NotificationService {
    static let shared = NotificationService()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { print("Notification auth error: \(error)") }
        }
    }

    func notify(tasks: [TaskItem]) {
        guard !tasks.isEmpty else { return }

        if tasks.count <= 5 {
            for task in tasks {
                deliver(task: task)
            }
        } else {
            deliverGrouped(count: tasks.count)
        }
    }

    private func deliver(task: TaskItem) {
        let identifier = notificationID(for: task)
        let center = UNUserNotificationCenter.current()

        // Remove stale notification with same ID before re-delivering
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = String(task.text.prefix(80))
        content.subtitle = task.filePath.lastPathComponent
        content.body = task.dueDateDisplayString
        content.sound = .default
        content.userInfo = [kFilePathUserInfoKey: task.filePath.path]

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        center.add(request) { error in
            if let error { print("Notification delivery error: \(error)") }
        }
    }

    private func deliverGrouped(count: Int) {
        let identifier = "tpreminders.grouped"
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "\(count) tasks are due"
        content.body = "Open TPReminders to review"
        content.sound = .default
        content.userInfo = [kFilePathUserInfoKey: ""]

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        center.add(request) { error in
            if let error { print("Notification delivery error: \(error)") }
        }
    }

    func handleResponse(_ response: UNNotificationResponse, openPreferences: @escaping () -> Void) {
        let filePath = response.notification.request.content.userInfo[kFilePathUserInfoKey] as? String ?? ""
        if filePath.isEmpty {
            openPreferences()
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
        }
    }

    private func notificationID(for task: TaskItem) -> String {
        "\(task.filePath.lastPathComponent):\(task.lineNumber)"
    }
}
