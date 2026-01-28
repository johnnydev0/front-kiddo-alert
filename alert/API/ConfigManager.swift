//
//  ConfigManager.swift
//  alert
//
//  Phase 3: Configuration management
//  Reads settings from Config.plist for easy environment switching
//

import Foundation

class ConfigManager {
    static let shared = ConfigManager()

    private let config: [String: Any]

    // MARK: - API Configuration

    var apiBaseURL: String {
        config["API_BASE_URL"] as? String ?? "http://localhost:3000/api/v1"
    }

    var apiTimeout: TimeInterval {
        TimeInterval(config["API_TIMEOUT"] as? Int ?? 30)
    }

    // MARK: - Initialization

    private init() {
        // Try to load Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            self.config = dict
            print("✅ Config loaded from Config.plist")
            print("   API_BASE_URL: \(apiBaseURL)")
        } else {
            print("⚠️ Config.plist not found, using defaults")
            self.config = [:]
        }
    }

    // MARK: - Debug

    func printConfig() {
        print("📋 Current Configuration:")
        print("   API Base URL: \(apiBaseURL)")
        print("   API Timeout: \(apiTimeout)s")
    }
}
