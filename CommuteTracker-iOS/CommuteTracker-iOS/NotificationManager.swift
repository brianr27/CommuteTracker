import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    init() {
        checkAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("❌ Notification authorization error: \(error.localizedDescription)")
                }
            }
        }
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func sendDelayAlert(destination: String, currentDuration: String, delayMinutes: Int, distance: String) {
        guard isAuthorized else {
            print("⚠️ Notifications not authorized")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🚨 Traffic Delay Alert"
        content.body = "\(destination) is delayed by \(delayMinutes) mins! Current time: \(currentDuration)"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "COMMUTE_DELAY"

        // Create a unique identifier for this notification
        let identifier = "commute-delay-\(destination)-\(Date().timeIntervalSince1970)"

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("✅ Delay notification sent: \(destination) - \(delayMinutes) mins delay")
            }
        }
    }
}
