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
    public let lastLoginAt: Date?
    public let phoneE164Hashed: String
    public let phoneVerifiedAt: Date?
    public let emailAddressHashed: String?
    public let emailDomain: String?
    public let emailVerifiedAt: Date?
    public let updatedAt: Date
    public let schemaVersion: Int
}
