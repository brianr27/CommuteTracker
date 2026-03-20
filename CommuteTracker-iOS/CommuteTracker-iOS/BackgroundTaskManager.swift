import Foundation
import BackgroundTasks
import CoreLocation

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private let taskIdentifier = "com.commutetracker.refresh"

    private init() {}

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        print("✅ Background task registered: \(taskIdentifier)")
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)

        // Request refresh in 15 minutes
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background refresh scheduled for 15 minutes from now")
        } catch {
            print("❌ Failed to schedule background refresh: \(error.localizedDescription)")
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("🔄 Background refresh started")

        // Schedule the next refresh
        scheduleBackgroundRefresh()

        // Set expiration handler
        task.expirationHandler = {
            print("⚠️ Background task expired")
        }

        let settings = SettingsManager.shared

        // Only proceed if alerts are enabled
        guard settings.alertsEnabled else {
            task.setTaskCompleted(success: true)
            return
        }

        // Create managers for background work
        let locationManager = LocationManager()
        let commuteManager = CommuteManager()

        // Request location and update commute times
        locationManager.requestLocation()

        // Wait a bit for location to be obtained
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak locationManager, weak commuteManager] in
            guard let locationManager = locationManager,
                  let commuteManager = commuteManager,
                  let location = locationManager.location else {
                print("❌ Failed to get location in background")
                task.setTaskCompleted(success: false)
                return
            }

            // Update commute times
            commuteManager.updateCommuteTimes(
                from: location,
                homeAddress: settings.homeAddress,
                officeAddress: settings.officeAddress,
                apiKey: settings.apiKey
            )

            // Give API calls time to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                print("✅ Background refresh completed")
                task.setTaskCompleted(success: true)
            }
        }
    }

    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        print("❌ Background tasks cancelled")
    }
}
