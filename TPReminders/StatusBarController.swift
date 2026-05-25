import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem
    private var statusMenuItem: NSMenuItem!
    private var loginItem: NSMenuItem!
    private let loginItemService: LoginItemService
    private let scheduler: ScanScheduler
    private let openPreferences: () -> Void
    private let triggerScan: () -> Void

    init(
        loginItemService: LoginItemService,
        scheduler: ScanScheduler,
        openPreferences: @escaping () -> Void,
        triggerScan: @escaping () -> Void
    ) {
        self.loginItemService = loginItemService
        self.scheduler = scheduler
        self.openPreferences = openPreferences
        self.triggerScan = triggerScan

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "TPReminders")
            button.image?.isTemplate = true
        }

        buildMenu()
    }

    func updateStatus(taskCount: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if taskCount == 0 {
                self.statusMenuItem.title = "All clear"
            } else {
                self.statusMenuItem.title = taskCount == 1 ? "1 task due" : "\(taskCount) tasks due"
            }
        }
    }

    private func buildMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "TPReminders", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        statusMenuItem = NSMenuItem(title: "Scanning…", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(.separator())

        menu.addItem(withTitle: "Scan Now", action: #selector(scanNow), keyEquivalent: "r")
            .target = self

        menu.addItem(withTitle: "Preferences…", action: #selector(openPreferencesWindow), keyEquivalent: ",")
            .target = self

        menu.addItem(.separator())

        loginItem = NSMenuItem(
            title: "Start at Login",
            action: #selector(toggleLoginItem),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = loginItemService.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        menu.addItem(withTitle: "Quit TPReminders", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem.menu = menu
    }

    @objc private func scanNow() {
        scheduler.triggerNow()
    }

    @objc private func openPreferencesWindow() {
        openPreferences()
    }

    @objc private func toggleLoginItem() {
        let newState = !loginItemService.isEnabled
        loginItemService.setEnabled(newState)
        loginItem.state = newState ? .on : .off
    }
}
