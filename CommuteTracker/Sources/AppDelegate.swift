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
            button.action = #selector(handleStatusItemClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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

    @objc func handleStatusItemClick() {
        // Check which mouse button was clicked
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                showMenu()
            } else {
                togglePopover()
            }
        }
    }

    func showMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Commute Tracker", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Clear menu after showing so left-click works next time
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
