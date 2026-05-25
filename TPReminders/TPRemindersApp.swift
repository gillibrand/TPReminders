import SwiftUI

@main
struct TPRemindersApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible windows — the app lives entirely in the menu bar.
        // Preferences are opened imperatively from AppDelegate via NSWindow.
        Settings {
            EmptyView()
        }
    }
}
