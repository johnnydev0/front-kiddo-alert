//
//  KeychainHelper.swift
//  alert
//
//  Phase 3: Secure token storage using iOS Keychain
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private let service = "com.kidoalert.app"

    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let deviceId = "device_id"
        static let userId = "user_id"
    }

    private init() {}

    // MARK: - Access Token

    var accessToken: String? {
        get { read(key: Keys.accessToken) }
        set {
            if let value = newValue {
                save(key: Keys.accessToken, value: value)
            } else {
                delete(key: Keys.accessToken)
            }
        }
    }

    // MARK: - Refresh Token

    var refreshToken: String? {
        get { read(key: Keys.refreshToken) }
        set {
            if let value = newValue {
                save(key: Keys.refreshToken, value: value)
            } else {
                delete(key: Keys.refreshToken)
            }
        }
    }

    // MARK: - Device ID

    var deviceId: String {
        get {
            if let existing = read(key: Keys.deviceId) {
                return existing
            }
            // Generate new device ID if none exists
            let newId = UUID().uuidString
            save(key: Keys.deviceId, value: newId)
            return newId
        }
        set {
            save(key: Keys.deviceId, value: newValue)
        }
    }

    // MARK: - User ID

    var userId: String? {
        get { read(key: Keys.userId) }
        set {
            if let value = newValue {
                save(key: Keys.userId, value: value)
            } else {
                delete(key: Keys.userId)
            }
        }
    }

    // MARK: - Convenience

    var isAuthenticated: Bool {
        accessToken != nil
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        userId = nil
    }

    func clearAll() {
        clearTokens()
        delete(key: Keys.deviceId)
    }

    // MARK: - Private Keychain Operations

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("⚠️ Keychain save error for \(key): \(status)")
        }
    }

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
