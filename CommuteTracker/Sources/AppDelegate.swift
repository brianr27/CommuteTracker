import AppKit
import SwiftUI
import CoreLocation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var locationManager: LocationManager!
    var commuteManager: CommuteManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "car.fill", accessibilityDescription: "Commute Tracker")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Initialize managers
        locationManager = LocationManager()
        commuteManager = CommuteManager()

        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 400)
        popover.behavior = .transient

        let contentView = ContentView(
            locationManager: locationManager,
            commuteManager: commuteManager
        )
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
