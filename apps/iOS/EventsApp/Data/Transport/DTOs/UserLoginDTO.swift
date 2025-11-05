//
//  UserLoginDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct UserLoginDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let lastLoginAt: Date?  // Local-only, not synced
    public let phoneE164Hashed: String  // Synced for contact matching
    public let phoneVerifiedAt: Date?
    public let emailAddressHashed: String?  // Synced for contact matching
    public let emailDomain: String?  // Local-only, not synced
    public let emailVerifiedAt: Date?
    public let updatedAt: Date
    public let schemaVersion: Int
}
