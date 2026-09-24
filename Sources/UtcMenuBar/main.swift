import AppKit

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarClock = MenuBarClock()

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarClock.start()
    }
}

@MainActor
private final class MenuBarClock: NSObject {
    private let statusItem: NSStatusItem = {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "com.harrisonleath.utcmenu.status-item"
        return item
    }()
    private let clockFont = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
    private let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    private let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    private var updateTimer: Timer?

    func start() {
        guard let button = statusItem.button else { return }

        button.imagePosition = .noImage
        button.font = clockFont
        button.toolTip = "Current Coordinated Universal Time"
        statusItem.menu = makeMenu()

        updateClock()
        scheduleUpdates()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(
            withTitle: "Copy UTC timestamp",
            action: #selector(copyTimestamp),
            keyEquivalent: "c"
        ).target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit UTC Clock", action: #selector(quit), keyEquivalent: "q").target = self
        return menu
    }

    private func scheduleUpdates() {
        let now = Date().timeIntervalSince1970
        let secondsUntilNextMinute = 60 - now.truncatingRemainder(dividingBy: 60)
        let timer = Timer(
            fireAt: Date(timeIntervalSinceNow: secondsUntilNextMinute),
            interval: 60,
            target: self,
            selector: #selector(updateClock),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer
    }

    @objc private func updateClock() {
        guard let button = statusItem.button else { return }
        let now = Date()
        let title = "\(clockFormatter.string(from: now)) UTC"
        button.title = title
        button.toolTip = "UTC: \(timestampFormatter.string(from: now))"
    }

    @objc private func copyTimestamp() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(timestampFormatter.string(from: Date()), forType: .string)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
