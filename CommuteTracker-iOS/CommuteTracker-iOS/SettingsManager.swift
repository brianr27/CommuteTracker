import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var apiKey: String {
        didSet {
            saveAPIKey(apiKey)
        }
    }

    @Published var homeAddress: String {
        didSet {
            UserDefaults.standard.set(homeAddress, forKey: "homeAddress")
        }
    }

    @Published var officeAddress: String {
        didSet {
            UserDefaults.standard.set(officeAddress, forKey: "officeAddress")
        }
    }

    @Published var alertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(alertsEnabled, forKey: "alertsEnabled")
        }
    }

    @Published var delayThresholdMinutes: Int {
        didSet {
            UserDefaults.standard.set(delayThresholdMinutes, forKey: "delayThresholdMinutes")
        }
    }

    @Published var baselineHomeDrivingMinutes: Int {
        didSet {
            UserDefaults.standard.set(baselineHomeDrivingMinutes, forKey: "baselineHomeDrivingMinutes")
        }
    }

    @Published var baselineOfficeDrivingMinutes: Int {
        didSet {
            UserDefaults.standard.set(baselineOfficeDrivingMinutes, forKey: "baselineOfficeDrivingMinutes")
        }
    }

    @Published var monitorHomeRoute: Bool {
        didSet {
            UserDefaults.standard.set(monitorHomeRoute, forKey: "monitorHomeRoute")
        }
    }

    @Published var monitorOfficeRoute: Bool {
        didSet {
            UserDefaults.standard.set(monitorOfficeRoute, forKey: "monitorOfficeRoute")
        }
    }

    private let keychainKey = "com.commutetracker.apikey"

    private init() {
        // Load API key from Keychain (secure)
        self.apiKey = KeychainHelper.shared.getString(keychainKey) ?? ""

        // Load addresses from UserDefaults (less sensitive)
        self.homeAddress = UserDefaults.standard.string(forKey: "homeAddress") ?? ""
        self.officeAddress = UserDefaults.standard.string(forKey: "officeAddress") ?? ""

        // Load alert settings
        self.alertsEnabled = UserDefaults.standard.object(forKey: "alertsEnabled") as? Bool ?? false
        self.delayThresholdMinutes = UserDefaults.standard.object(forKey: "delayThresholdMinutes") as? Int ?? 10
        self.baselineHomeDrivingMinutes = UserDefaults.standard.object(forKey: "baselineHomeDrivingMinutes") as? Int ?? 0
        self.baselineOfficeDrivingMinutes = UserDefaults.standard.object(forKey: "baselineOfficeDrivingMinutes") as? Int ?? 0
        self.monitorHomeRoute = UserDefaults.standard.object(forKey: "monitorHomeRoute") as? Bool ?? true
        self.monitorOfficeRoute = UserDefaults.standard.object(forKey: "monitorOfficeRoute") as? Bool ?? false

        // Migrate old API key from UserDefaults to Keychain if it exists
        migrateAPIKeyToKeychain()
    }

    private func saveAPIKey(_ key: String) {
        if key.isEmpty {
            _ = KeychainHelper.shared.delete(keychainKey)
        } else {
            _ = KeychainHelper.shared.save(key, for: keychainKey)
        }
    }

    private func migrateAPIKeyToKeychain() {
        // Check if there's an old API key in UserDefaults
        if let oldKey = UserDefaults.standard.string(forKey: "googleMapsAPIKey"), !oldKey.isEmpty {
            print("🔄 Migrating API key from UserDefaults to Keychain...")

            // Save to Keychain
            if KeychainHelper.shared.save(oldKey, for: keychainKey) {
                // Remove from UserDefaults
                UserDefaults.standard.removeObject(forKey: "googleMapsAPIKey")
                self.apiKey = oldKey
                print("✅ API key migrated to secure Keychain storage")
            }
        }
    }

    // Clear all settings (useful for logout/reset)
    func clearAll() {
        apiKey = ""
        homeAddress = ""
        officeAddress = ""
        alertsEnabled = false
        delayThresholdMinutes = 10
        baselineHomeDrivingMinutes = 0
        baselineOfficeDrivingMinutes = 0
        monitorHomeRoute = true
        monitorOfficeRoute = false
        _ = KeychainHelper.shared.delete(keychainKey)
        UserDefaults.standard.removeObject(forKey: "homeAddress")
        UserDefaults.standard.removeObject(forKey: "officeAddress")
        UserDefaults.standard.removeObject(forKey: "alertsEnabled")
        UserDefaults.standard.removeObject(forKey: "delayThresholdMinutes")
        UserDefaults.standard.removeObject(forKey: "baselineHomeDrivingMinutes")
        UserDefaults.standard.removeObject(forKey: "baselineOfficeDrivingMinutes")
        UserDefaults.standard.removeObject(forKey: "monitorHomeRoute")
        UserDefaults.standard.removeObject(forKey: "monitorOfficeRoute")
    }
}
