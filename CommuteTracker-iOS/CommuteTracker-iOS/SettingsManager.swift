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

    private let keychainKey = "com.commutetracker.apikey"

    private init() {
        // Load API key from Keychain (secure)
        self.apiKey = KeychainHelper.shared.getString(keychainKey) ?? ""

        // Load addresses from UserDefaults (less sensitive)
        self.homeAddress = UserDefaults.standard.string(forKey: "homeAddress") ?? ""
        self.officeAddress = UserDefaults.standard.string(forKey: "officeAddress") ?? ""

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
        _ = KeychainHelper.shared.delete(keychainKey)
        UserDefaults.standard.removeObject(forKey: "homeAddress")
        UserDefaults.standard.removeObject(forKey: "officeAddress")
    }
}
