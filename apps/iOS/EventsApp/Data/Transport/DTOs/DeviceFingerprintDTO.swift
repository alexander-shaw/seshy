//
//  DeviceFingerprintDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct DeviceFingerprintDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let deviceIdentifier: String
    public let deviceModel: String
    public let systemVersion: String
    public let appVersion: String
    public let regionCode: String
    public let timezone: String
    public let languageCode: String
    public let lastActiveAt: Date
    public let loginAttemptCount: Int
    public let isLockedOut: Bool
    public let lockoutUntil: Date?
    
    public let updatedAt: Date
    public let schemaVersion: Int
}
