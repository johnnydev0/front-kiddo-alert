//
//  APIService.swift
//  alert
//
//  Phase 3: HTTP client for backend communication
//  Handles authentication, token refresh, and API calls
//

import Foundation

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(code: String, message: String)
    case unauthorized
    case forbidden
    case notFound
    case limitExceeded
    case networkError(Error)
    case unknown(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "Nenhum dado recebido"
        case .decodingError(let error):
            return "Erro ao processar resposta: \(error.localizedDescription)"
        case .serverError(_, let message):
            return message
        case .unauthorized:
            return "Sessão expirada. Faça login novamente."
        case .forbidden:
            return "Você não tem permissão para esta ação."
        case .notFound:
            return "Recurso não encontrado."
        case .limitExceeded:
            return "Limite do plano atingido. Faça upgrade para continuar."
        case .networkError(let error):
            return "Erro de conexão: \(error.localizedDescription)"
        case .unknown(let code):
            return "Erro desconhecido (código \(code))"
        }
    }
}

// MARK: - API Service

class APIService {
    static let shared = APIService()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let keychain = KeychainHelper.shared

    // Callback for auth failures (to trigger re-auth in AppState)
    var onAuthFailure: (() -> Void)?

    private init() {
        // Load URL from Config.plist
        let configManager = ConfigManager.shared
        self.baseURL = configManager.apiBaseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configManager.apiTimeout
        config.timeoutIntervalForResource = configManager.apiTimeout * 2
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()

        print("🌐 API Service initialized with base URL: \(baseURL)")
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        authenticated: Bool = true,
        isRetry: Bool = false
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Add auth header if needed
        if authenticated, let token = keychain.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if present (only set Content-Type when there's a body)
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown(0)
            }

            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    print("❌ Decoding error: \(error)")
                    print("📦 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    throw APIError.decodingError(error)
                }

            case 401:
                // Don't retry if this is already a retry (prevents infinite loop)
                if isRetry {
                    print("⚠️ 401 on retry - not retrying again to prevent loop")
                    onAuthFailure?()
                    throw APIError.unauthorized
                }
                // Try to refresh token
                if authenticated {
                    let refreshed = await refreshTokenAndRetry()
                    if refreshed {
                        // Retry the original request (mark as retry)
                        return try await self.request(
                            endpoint: endpoint,
                            method: method,
                            body: body,
                            authenticated: authenticated,
                            isRetry: true
                        )
                    }
                }
                onAuthFailure?()
                throw APIError.unauthorized

            case 403:
                // Check if it's a limit exceeded error
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data),
                   errorResponse.error.code == "LIMIT_EXCEEDED" {
                    throw APIError.limitExceeded
                }
                throw APIError.forbidden

            case 404:
                throw APIError.notFound

            default:
                // Try to parse error response
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(
                        code: errorResponse.error.code,
                        message: errorResponse.error.message
                    )
                }
                throw APIError.unknown(httpResponse.statusCode)
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // Request that doesn't expect a response body
    func requestVoid(
        endpoint: String,
        method: String = "POST",
        body: Encodable? = nil,
        authenticated: Bool = true,
        isRetry: Bool = false
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if authenticated, let token = keychain.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown(0)
            }

            switch httpResponse.statusCode {
            case 200...299:
                return // Success, no body expected

            case 401:
                // Don't retry if this is already a retry (prevents infinite loop)
                if isRetry {
                    print("⚠️ 401 on retry - not retrying again to prevent loop")
                    onAuthFailure?()
                    throw APIError.unauthorized
                }
                if authenticated {
                    let refreshed = await refreshTokenAndRetry()
                    if refreshed {
                        return try await self.requestVoid(
                            endpoint: endpoint,
                            method: method,
                            body: body,
                            authenticated: authenticated,
                            isRetry: true
                        )
                    }
                }
                onAuthFailure?()
                throw APIError.unauthorized

            case 403:
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data),
                   errorResponse.error.code == "LIMIT_EXCEEDED" {
                    throw APIError.limitExceeded
                }
                throw APIError.forbidden

            case 404:
                throw APIError.notFound

            default:
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(
                        code: errorResponse.error.code,
                        message: errorResponse.error.message
                    )
                }
                throw APIError.unknown(httpResponse.statusCode)
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Token Refresh

    private var isRefreshing = false

    private func refreshTokenAndRetry() async -> Bool {
        guard !isRefreshing else { return false }
        guard let refreshToken = keychain.refreshToken else { return false }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let body = RefreshTokenRequest(refreshToken: refreshToken)
            let response: AuthResponse = try await request(
                endpoint: "/auth/refresh",
                method: "POST",
                body: body,
                authenticated: false
            )

            keychain.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            print("✅ Token refreshed successfully")
            return true
        } catch {
            print("❌ Token refresh failed: \(error)")
            return false
        }
    }

    // MARK: - Auth Endpoints

    func deviceAuth(mode: String) async throws -> AuthResponse {
        let body = DeviceAuthRequest(deviceId: keychain.deviceId, mode: mode)
        let response: AuthResponse = try await request(
            endpoint: "/auth/device",
            method: "POST",
            body: body,
            authenticated: false
        )

        keychain.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        keychain.userId = response.user.id

        return response
    }

    func register(email: String, password: String, name: String) async throws -> AuthResponse {
        let body = RegisterRequest(email: email, password: password, name: name)
        return try await request(
            endpoint: "/auth/register",
            method: "POST",
            body: body,
            authenticated: true
        )
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password, deviceId: keychain.deviceId)
        let response: AuthResponse = try await request(
            endpoint: "/auth/login",
            method: "POST",
            body: body,
            authenticated: false
        )

        keychain.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        keychain.userId = response.user.id

        return response
    }

    func logout() async throws {
        try await requestVoid(endpoint: "/auth/logout", method: "POST")
        keychain.clearTokens()
    }

    // MARK: - User Endpoints

    func getCurrentUser() async throws -> APIUser {
        let response: UserResponse = try await request(endpoint: "/users/me")
        return response.user
    }

    func getUserLimits() async throws -> UserLimitsResponse {
        return try await request(endpoint: "/users/me/limits")
    }

    func updateUser(name: String? = nil, email: String? = nil) async throws -> APIUser {
        let body = UpdateUserRequest(name: name, email: email)
        let response: UserResponse = try await request(
            endpoint: "/users/me",
            method: "PATCH",
            body: body
        )
        return response.user
    }

    func getMyGuardians() async throws -> [APIGuardian] {
        let response: ChildGuardiansResponse = try await request(endpoint: "/users/me/guardians")
        return response.guardians
    }

    // MARK: - Children Endpoints

    func getChildren() async throws -> [APIChild] {
        let response: ChildrenListResponse = try await request(endpoint: "/children")
        return response.children
    }

    func getChild(id: String) async throws -> APIChildDetail {
        let response: ChildResponse = try await request(endpoint: "/children/\(id)")
        return response.child
    }

    func createChild(name: String) async throws -> CreateChildResponse {
        let body = CreateChildRequest(name: name)
        return try await request(endpoint: "/children", method: "POST", body: body)
    }

    func updateChild(id: String, name: String) async throws -> APIChild {
        let body = UpdateChildRequest(name: name)
        let response: ChildResponse = try await request(
            endpoint: "/children/\(id)",
            method: "PATCH",
            body: body
        )
        return APIChild(
            id: response.child.id,
            userId: response.child.userId,
            name: response.child.name,
            isSharing: response.child.isSharing,
            lastLatitude: response.child.lastLatitude,
            lastLongitude: response.child.lastLongitude,
            lastUpdateTime: response.child.lastUpdateTime,
            batteryLevel: response.child.batteryLevel,
            owner: nil
        )
    }

    func deleteChild(id: String) async throws {
        try await requestVoid(endpoint: "/children/\(id)", method: "DELETE")
    }

    func createChildInvite(childId: String) async throws -> InviteResponse {
        return try await request(endpoint: "/children/\(childId)/invite", method: "POST")
    }

    // MARK: - Alerts Endpoints

    func getAlerts(childId: String? = nil) async throws -> [APIAlert] {
        var endpoint = "/alerts"
        if let childId = childId {
            endpoint += "?childId=\(childId)"
        }
        let response: AlertsListResponse = try await request(endpoint: endpoint)
        return response.alerts
    }

    func createAlert(childId: String, name: String, address: String?, latitude: Double, longitude: Double, radius: Int = 100) async throws -> APIAlert {
        let body = CreateAlertRequest(
            childId: childId,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )
        let response: AlertResponse = try await request(endpoint: "/alerts", method: "POST", body: body)
        return response.alert
    }

    func updateAlert(id: String, name: String? = nil, isActive: Bool? = nil, address: String? = nil, latitude: Double? = nil, longitude: Double? = nil, radius: Int? = nil) async throws -> APIAlert {
        let body = UpdateAlertRequest(
            name: name,
            isActive: isActive,
            address: address,
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )
        let response: AlertResponse = try await request(
            endpoint: "/alerts/\(id)",
            method: "PATCH",
            body: body
        )
        return response.alert
    }

    func deleteAlert(id: String) async throws {
        try await requestVoid(endpoint: "/alerts/\(id)", method: "DELETE")
    }

    // MARK: - Location Endpoints (Child Mode)

    func updateLocation(latitude: Double, longitude: Double, batteryLevel: Int?) async throws -> LocationUpdateResponse {
        let body = LocationUpdateRequest(
            latitude: latitude,
            longitude: longitude,
            batteryLevel: batteryLevel
        )
        return try await request(endpoint: "/location/update", method: "POST", body: body)
    }

    func pauseLocationSharing() async throws {
        try await requestVoid(endpoint: "/location/pause", method: "POST")
    }

    func resumeLocationSharing() async throws {
        try await requestVoid(endpoint: "/location/resume", method: "POST")
    }

    // MARK: - History Endpoints

    func getHistory(childId: String? = nil, days: Int = 7) async throws -> HistoryResponse {
        var endpoint = "/history?days=\(days)"
        if let childId = childId {
            endpoint += "&childId=\(childId)"
        }
        return try await request(endpoint: endpoint)
    }

    // MARK: - Invite Endpoints

    func getInviteDetails(token: String) async throws -> InviteDetailsResponse {
        return try await request(endpoint: "/invites/\(token)", authenticated: false)
    }

    func acceptInvite(token: String) async throws {
        try await requestVoid(endpoint: "/invites/\(token)/accept", method: "POST")
    }

    func createGuardianInvite(childId: String) async throws -> InviteResponse {
        let body = CreateInviteRequest(type: "add_guardian", childId: childId)
        return try await request(endpoint: "/invites", method: "POST", body: body)
    }

    // MARK: - Device Endpoints

    func registerPushToken(_ token: String) async throws {
        let body = RegisterDeviceTokenRequest(pushToken: token, platform: "ios")
        try await requestVoid(endpoint: "/devices/token", method: "POST", body: body)
    }

    func removePushToken(_ token: String) async throws {
        let body = RegisterDeviceTokenRequest(pushToken: token, platform: "ios")
        try await requestVoid(endpoint: "/devices/token", method: "DELETE", body: body)
    }

    // MARK: - Subscription Endpoints

    func verifyAppleReceipt(_ receiptData: String) async throws {
        let body = VerifyReceiptRequest(appleReceiptData: receiptData)
        try await requestVoid(endpoint: "/subscriptions/verify", method: "POST", body: body)
    }

    func getSubscriptionStatus() async throws -> SubscriptionStatusResponse {
        return try await request(endpoint: "/subscriptions/status")
    }
}
