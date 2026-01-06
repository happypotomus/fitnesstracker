//
//  KeychainManager.swift
//  FitnessTracker
//
//  Secure storage for sensitive data using iOS Keychain
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.fitnessapp.FitnessTracker"
    private let apiKeyAccount = "openai-api-key"

    private init() {}

    // MARK: - API Key Methods

    /// Saves the OpenAI API key securely to the keychain
    func saveAPIKey(_ key: String) -> Bool {
        // Delete any existing key first
        deleteAPIKey()

        guard let data = key.data(using: .utf8) else {
            print("❌ Failed to convert API key to data")
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            print("✅ API key saved to keychain")
            return true
        } else {
            print("❌ Failed to save API key to keychain: \(status)")
            return false
        }
    }

    /// Retrieves the OpenAI API key from the keychain
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            if let data = result as? Data,
               let key = String(data: data, encoding: .utf8) {
                print("✅ API key retrieved from keychain")
                return key
            }
        } else if status == errSecItemNotFound {
            print("ℹ️ No API key found in keychain")
        } else {
            print("❌ Failed to retrieve API key from keychain: \(status)")
        }

        return nil
    }

    /// Deletes the API key from the keychain
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            print("✅ API key deleted from keychain")
            return true
        } else if status == errSecItemNotFound {
            // Not an error - key didn't exist
            return true
        } else {
            print("❌ Failed to delete API key from keychain: \(status)")
            return false
        }
    }

    /// Checks if an API key exists in the keychain
    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }

    // MARK: - Validation

    /// Validates the format of an OpenAI API key
    static func isValidAPIKeyFormat(_ key: String) -> Bool {
        // OpenAI keys start with "sk-" and have a minimum length
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check minimum length and prefix
        return trimmedKey.count >= 20 &&
               (trimmedKey.hasPrefix("sk-") || trimmedKey.hasPrefix("sk_"))
    }
}
