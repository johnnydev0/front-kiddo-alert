//
//  APIModels.swift
//  alert
//
//  Phase 3: API Data Transfer Objects
//  These models match the backend API responses
//

import Foundation

// MARK: - Auth Responses

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: APIUser
}

struct APIUser: Codable {
    let id: String
    let deviceId: String?
    let email: String?
    let name: String?
    let mode: String
    let plan: String
    let planExpiresAt: String?
}

struct UserResponse: Codable {
    let user: APIUser
}

struct UserLimitsResponse: Codable {
    let plan: String
    let limits: PlanLimits
    let current: CurrentUsage
}

struct PlanLimits: Codable {
    let maxAlerts: Int
    let maxChildren: Int
    let maxGuardians: Int
    let historyDays: Int
}

struct CurrentUsage: Codable {
    let children: Int
    let alerts: Int
    let guardians: Int
}

// MARK: - Children

struct ChildrenListResponse: Codable {
    let children: [APIChild]
}

struct ChildResponse: Codable {
    let child: APIChildDetail
}

struct CreateChildResponse: Codable {
    let child: APIChild
    let inviteToken: String
    let inviteExpiresAt: String
}

struct APIChild: Codable {
    let id: String
    let userId: String?
    let name: String
    let isSharing: Bool
    let lastLatitude: Double?
    let lastLongitude: Double?
    let lastUpdateTime: String?
    let batteryLevel: Int?
    let owner: APIChildOwner?
}

struct APIChildDetail: Codable {
    let id: String
    let userId: String?
    let name: String
    let isSharing: Bool
    let lastLatitude: Double?
    let lastLongitude: Double?
    let lastUpdateTime: String?
    let batteryLevel: Int?
    let alerts: [APIAlert]?
    let historyEvents: [APIHistoryEvent]?
    let guardians: [APIGuardian]?
}

struct APIChildOwner: Codable {
    let id: String
    let name: String?
}

struct APIGuardian: Codable {
    let id: String
    let name: String?
    let email: String?
}

// MARK: - Alerts

struct AlertsListResponse: Codable {
    let alerts: [APIAlert]
}

struct AlertResponse: Codable {
    let alert: APIAlert
}

struct APIAlert: Codable {
    let id: String
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let radius: Int
    let isActive: Bool
    let startTime: String?
    let endTime: String?
    let scheduleDays: [Int]?
    let child: APIAlertChild?
}

struct APIAlertChild: Codable {
    let id: String
    let name: String
}

// MARK: - Location

struct LocationUpdateRequest: Codable {
    let latitude: Double
    let longitude: Double
    let batteryLevel: Int?
}

struct LocationUpdateResponse: Codable {
    let success: Bool
    let events: Int?
    let triggeredAlerts: [String]?
}

// MARK: - History

struct HistoryResponse: Codable {
    let events: [APIHistoryEvent]
    let limit: HistoryLimit?
}

struct HistoryLimit: Codable {
    let days: Int
    let isPremium: Bool
}

struct APIHistoryEvent: Codable {
    let id: String
    let type: String // "arrived", "left", "paused", "resumed"
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let timestamp: String
    let child: APIEventChild?
    let alert: APIEventAlert?
}

struct APIEventChild: Codable {
    let id: String
    let name: String
}

struct APIEventAlert: Codable {
    let id: String
    let name: String
}

// MARK: - Invites

struct InviteResponse: Codable {
    let token: String
    let expiresAt: String
}

struct InviteDetailsResponse: Codable {
    let invite: InviteDetails
    let createdByName: String?
    let childName: String?
}

struct InviteDetails: Codable {
    let token: String
    let type: String // "add_child", "add_guardian"
    let expiresAt: String
}

struct CreateInviteRequest: Codable {
    let type: String
    let childId: String
}

// MARK: - Devices

struct RegisterDeviceTokenRequest: Codable {
    let pushToken: String
    let platform: String
}

// MARK: - Subscriptions

struct VerifyReceiptRequest: Codable {
    let appleReceiptData: String
}

struct SubscriptionStatusResponse: Codable {
    let isPremium: Bool
    let subscription: SubscriptionDetails?
}

struct SubscriptionDetails: Codable {
    let plan: String
    let status: String
    let expiresAt: String
}

// MARK: - Error Response

struct APIErrorResponse: Codable {
    let error: APIErrorDetails
}

struct APIErrorDetails: Codable {
    let code: String
    let message: String
    let details: [String: String]?
}

// MARK: - Request Bodies

struct DeviceAuthRequest: Codable {
    let deviceId: String
    let mode: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
    let deviceId: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct CreateChildRequest: Codable {
    let name: String
}

struct UpdateChildRequest: Codable {
    let name: String?
}

struct CreateAlertRequest: Codable {
    let childId: String
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let radius: Int
    let startTime: String?
    let endTime: String?
    let scheduleDays: [Int]?
}

struct UpdateAlertRequest: Codable {
    let name: String?
    let isActive: Bool?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let radius: Int?
    let startTime: String?
    let endTime: String?
    let scheduleDays: [Int]?
}

struct UpdateUserRequest: Codable {
    let name: String?
    let email: String?
}

// MARK: - Child Guardians Response
struct ChildGuardiansResponse: Codable {
    let guardians: [APIGuardian]
}
