import AppKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let filesStore = WatchedFilesStore()
    let loginItemService = LoginItemService()
    let scanEngine = ScanEngine()
    let scheduler = ScanScheduler()

    private var statusBarController: StatusBarController?
    private var preferencesWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Command-Tab switcher (belt-and-suspenders with LSUIElement)
        NSApp.setActivationPolicy(.accessory)

        UNUserNotificationCenter.current().delegate = self
        NotificationService.shared.requestAuthorization()

        statusBarController = StatusBarController(
            loginItemService: loginItemService,
            scheduler: scheduler,
            openPreferences: { [weak self] in self?.showPreferences() },
            triggerScan: { [weak self] in self?.runScan() }
        )

        scheduler.start { [weak self] in
            self?.runScan()
        }
    }

    func runScan() {
        let tasks = scanEngine.scan(store: filesStore)
        statusBarController?.updateStatus(taskCount: tasks.count)
        NotificationService.shared.notify(tasks: tasks)
    }

    func showPreferences() {
        if let existing = preferencesWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = PreferencesView(store: filesStore, loginItemService: loginItemService, scheduler: scheduler)
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "TPReminders Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 460, height: 320))
        window.center()
        window.isReleasedWhenClosed = false
        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationService.shared.handleResponse(response) { [weak self] in
            self?.showPreferences()
        }
        completionHandler()
    }

    // Show notifications even when app is in foreground (unlikely for a menu bar app, but correct)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
