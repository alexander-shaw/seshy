//
//  UserProfileDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct UserProfileDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let displayName: String
    public let bio: String?
    public let dateOfBirth: Date?
    public let showAge: Bool
    public let genderCategoryRaw: Int16?
    public let genderIdentity: String?
    public let showGender: Bool
    public let isVerified: Bool
    public let wasVerifiedAt: Date?

    public let updatedAt: Date
    public let schemaVersion: Int
}


