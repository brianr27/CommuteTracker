import SwiftUI
import BackgroundTasks

@main
struct CommuteTrackerApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var commuteManager = CommuteManager()
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Register background tasks on app launch
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                locationManager: locationManager,
                commuteManager: commuteManager
            )
            .onAppear {
                // Request notification permissions if alerts are enabled
                if settings.alertsEnabled {
                    NotificationManager.shared.requestAuthorization()
                    BackgroundTaskManager.shared.scheduleBackgroundRefresh()
                }
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                // Schedule background refresh when app goes to background
                if settings.alertsEnabled {
                    BackgroundTaskManager.shared.scheduleBackgroundRefresh()
                }
            }
        }
    }
}
