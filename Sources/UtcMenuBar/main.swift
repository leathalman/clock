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
    private let clockFont = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
    private let pillColor = NSColor(srgbRed: 0.36, green: 0.40, blue: 0.45, alpha: 1)
    private let pillCornerRadius: CGFloat = 6
    private let pillHorizontalPadding: CGFloat = 10
    private let pillVerticalPadding: CGFloat = 4
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

        button.imagePosition = .imageOnly
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
        let title = "UTC \(clockFormatter.string(from: now))"
        button.image = makePillImage(title: title)
        button.toolTip = "UTC: \(timestampFormatter.string(from: now))"
    }

    private func makePillImage(title: String) -> NSImage {
        let text = NSAttributedString(
            string: title,
            attributes: [
                .font: clockFont,
                .foregroundColor: NSColor.white,
            ]
        )
        let textSize = text.size()
        let imageSize = NSSize(
            width: ceil(textSize.width + pillHorizontalPadding * 2),
            height: ceil(textSize.height + pillVerticalPadding * 2)
        )
        let pillColor = pillColor
        let pillCornerRadius = pillCornerRadius
        let image = NSImage(size: imageSize, flipped: false) { rect in
            pillColor.setFill()
            NSBezierPath(
                roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
                xRadius: pillCornerRadius,
                yRadius: pillCornerRadius
            ).fill()
            text.draw(
                at: NSPoint(
                    x: (imageSize.width - textSize.width) / 2,
                    y: (imageSize.height - textSize.height) / 2
                )
            )
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = title
        return image
    }

    @objc private func copyTimestamp() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(timestampFormatter.string(from: Date()), forType: .string)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
