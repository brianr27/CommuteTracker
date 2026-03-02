import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    // Save data to keychain
    func save(_ data: Data, for key: String) -> Bool {
        // Delete any existing item first
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            print("✅ Saved '\(key)' to Keychain")
            return true
        } else {
            print("❌ Failed to save '\(key)' to Keychain: \(status)")
            return false
        }
    }

    // Save string to keychain
    func save(_ string: String, for key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, for: key)
    }

    // Retrieve data from keychain
    func get(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            print("❌ Failed to retrieve '\(key)' from Keychain: \(status)")
            return nil
        }
    }

    // Retrieve string from keychain
    func getString(_ key: String) -> String? {
        guard let data = get(key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // Delete item from keychain
    func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
