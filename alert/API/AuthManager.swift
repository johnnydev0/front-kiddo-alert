//
//  AuthManager.swift
//  alert
//
//  Phase 3: Authentication state management
//  Handles device auth, login, logout, and user state
//

import Foundation
import Combine

enum AuthState {
    case unknown        // App just launched, checking auth
    case unauthenticated // No valid session
    case authenticated(APIUser) // Valid session with user data
}

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var state: AuthState = .unknown
    @Published private(set) var currentUser: APIUser?
    @Published private(set) var userLimits: UserLimitsResponse?
    @Published private(set) var isLoading = false
    @Published var error: String?

    private let api = APIService.shared
    private let keychain = KeychainHelper.shared

    var isAuthenticated: Bool {
        if case .authenticated = state { return true }
        return false
    }

    var userMode: UserMode {
        currentUser?.mode == "child" ? .crianca : .responsavel
    }

    var currentLimits: PlanLimits? {
        userLimits?.limits
    }

    private init() {
        // Set up auth failure callback
        api.onAuthFailure = { [weak self] in
            Task { @MainActor in
                self?.handleAuthFailure()
            }
        }
    }

    // MARK: - Initial Auth Check

    func checkAuthState() async {
        guard keychain.isAuthenticated else {
            state = .unauthenticated
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await api.getCurrentUser()
            currentUser = user
            state = .authenticated(user)

            // Also fetch limits
            userLimits = try? await api.getUserLimits()

            print("✅ Auth restored for user: \(user.name ?? user.id)")
        } catch {
            print("❌ Auth check failed: \(error)")
            // Token might be invalid, clear and require re-auth
            keychain.clearTokens()
            state = .unauthenticated
        }
    }

    // MARK: - Device Auth (Anonymous)

    func authenticateDevice(mode: UserMode) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let modeString = mode == .crianca ? "child" : "guardian"
            let response = try await api.deviceAuth(mode: modeString)

            currentUser = response.user
            state = .authenticated(response.user)

            // Fetch limits
            userLimits = try? await api.getUserLimits()

            print("✅ Device authenticated as \(modeString)")
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            throw apiError
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Device Auth (Silent - no state change)
    // Used when we need to authenticate but defer the state change
    // (e.g., child invite flow where we need to accept invite before navigating)

    func authenticateDeviceSilently(mode: UserMode) async throws -> APIUser {
        let modeString = mode == .crianca ? "child" : "guardian"
        let response = try await api.deviceAuth(mode: modeString)
        currentUser = response.user
        userLimits = try? await api.getUserLimits()
        print("✅ Device authenticated silently as \(modeString)")
        return response.user
    }

    func publishAuthState(_ user: APIUser) {
        state = .authenticated(user)
    }

    // MARK: - Register

    func register(email: String, password: String, name: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await api.register(email: email, password: password, name: name)

            currentUser = response.user
            state = .authenticated(response.user)

            print("✅ User registered: \(email)")
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            throw apiError
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await api.login(email: email, password: password)

            currentUser = response.user
            state = .authenticated(response.user)

            // Fetch limits
            userLimits = try? await api.getUserLimits()

            print("✅ User logged in: \(email)")
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            throw apiError
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Logout

    func logout() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await api.logout()
        } catch {
            print("⚠️ Logout API call failed: \(error)")
            // Continue with local logout anyway
        }

        keychain.clearTokens()
        currentUser = nil
        userLimits = nil
        state = .unauthenticated

        print("✅ User logged out")
    }

    // MARK: - Update User

    func updateUserName(_ name: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let updatedUser = try await api.updateUser(name: name)
            currentUser = updatedUser
            state = .authenticated(updatedUser)

            print("✅ User name updated to: \(name)")
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            throw apiError
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func updateUserProfile(name: String, email: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let updatedUser = try await api.updateUser(name: name, email: email)
            currentUser = updatedUser
            state = .authenticated(updatedUser)

            print("✅ User profile updated: \(name), \(email)")
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            throw apiError
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    var needsProfileSetup: Bool {
        guard let user = currentUser else { return false }
        return user.name == nil || user.name?.isEmpty == true
    }

    // MARK: - Refresh Limits

    func refreshLimits() async {
        userLimits = try? await api.getUserLimits()
    }

    // MARK: - Auth Failure Handler

    private func handleAuthFailure() {
        keychain.clearTokens()
        currentUser = nil
        userLimits = nil
        state = .unauthenticated
        error = "Sua sessão expirou. Por favor, faça login novamente."
    }

    // MARK: - Helpers

    func clearError() {
        error = nil
    }

    // Check if user can perform action based on limits
    func canAddChild() -> Bool {
        guard let limits = userLimits else { return true }
        return limits.current.children < limits.limits.maxChildren
    }

    func canAddAlert() -> Bool {
        guard let limits = userLimits else { return true }
        return limits.current.alerts < limits.limits.maxAlerts
    }

    func canAddGuardian() -> Bool {
        guard let limits = userLimits else { return true }
        return limits.current.guardians < limits.limits.maxGuardians
    }
}
