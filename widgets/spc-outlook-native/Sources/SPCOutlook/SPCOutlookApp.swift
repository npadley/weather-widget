import SwiftUI
import AppKit
import ServiceManagement

@main
struct SPCOutlookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No default windows — AppDelegate creates the floating widget window.
        Settings { EmptyView() }
    }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow?
    private var statusItem: NSStatusItem?

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from the Dock — behave like a pure desktop widget.
        NSApp.setActivationPolicy(.accessory)

        setupFloatingWindow()
        setupMenuBar()
    }

    // MARK: Floating window

    private func setupFloatingWindow() {
        let frame = loadWindowFrame()

        let win = NSWindow(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.hasShadow = true
        win.isMovableByWindowBackground = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        win.contentView = NSHostingView(rootView: ContentView())
        win.makeKeyAndOrderFront(nil)
        self.window = win

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: win
        )
    }

    @objc private func windowDidMove() {
        guard let frame = window?.frame else { return }
        saveWindowFrame(frame)
    }

    // MARK: Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "cloud.bolt.rain.fill",
                accessibilityDescription: "SPC Outlook"
            )
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let toggleTitle = window?.isVisible == true ? "Hide Widget" : "Show Widget"
        menu.addItem(NSMenuItem(
            title: toggleTitle,
            action: #selector(toggleWidget),
            keyEquivalent: "w"
        ))

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Refresh Now",
            action: #selector(refreshNow),
            keyEquivalent: "r"
        ))

        menu.addItem(.separator())

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.state = isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit SPC Outlook",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
    }

    // MARK: Menu actions

    @objc private func toggleWidget() {
        guard let win = window else { return }
        if win.isVisible {
            win.orderOut(nil)
        } else {
            win.makeKeyAndOrderFront(nil)
        }
        rebuildMenu()
    }

    @objc private func refreshNow() {
        // Post a notification that ContentView's ViewModel can observe, or
        // simply re-open the window which will trigger a fetch on next appear.
        // For simplicity, we post a distributed notification the ViewModel listens to.
        NotificationCenter.default.post(name: .refreshOutlookNow, object: nil)
    }

    @objc private func toggleLaunchAtLogin() {
        setLaunchAtLogin(!isLaunchAtLoginEnabled)
        rebuildMenu()
    }

    // MARK: Launch at login

    private var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Could not set login item: \(error)")
        }
    }

    // MARK: Window frame persistence

    private func loadWindowFrame() -> NSRect {
        let d = UserDefaults.standard
        let x = d.double(forKey: "windowX")
        let y = d.double(forKey: "windowY")
        let w: CGFloat = 520
        let h: CGFloat = 490   // slightly taller to fit day picker

        if x != 0 || y != 0 {
            return NSRect(x: x, y: y, width: w, height: h)
        }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSRect(x: screen.maxX - w - 20, y: screen.maxY - h - 20, width: w, height: h)
    }

    private func saveWindowFrame(_ frame: NSRect) {
        UserDefaults.standard.set(Double(frame.origin.x), forKey: "windowX")
        UserDefaults.standard.set(Double(frame.origin.y), forKey: "windowY")
    }
}

// MARK: - Notification

extension Notification.Name {
    static let refreshOutlookNow = Notification.Name("refreshOutlookNow")
}
