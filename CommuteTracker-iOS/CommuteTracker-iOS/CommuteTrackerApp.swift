import SwiftUI

@main
struct CommuteTrackerApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var commuteManager = CommuteManager()

    var body: some Scene {
        WindowGroup {
            ContentView(
                locationManager: locationManager,
                commuteManager: commuteManager
            )
        }
    }
}
