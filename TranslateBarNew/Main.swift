import AppKit
import SwiftUI

class TranslateBarAppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let view = TranslateBar()

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 360, height: 320)
        popover?.behavior = .transient
        popover?.contentViewController = NSViewController()
        popover?.contentViewController?.view = NSHostingView(rootView: view)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "TranslateBar")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        NSApp.setActivationPolicy(.accessory)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if let popover = popover, popover.isShown {
                popover.performClose(sender)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

@main
struct Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = TranslateBarAppDelegate()
        app.delegate = delegate
        app.run()
    }
}
