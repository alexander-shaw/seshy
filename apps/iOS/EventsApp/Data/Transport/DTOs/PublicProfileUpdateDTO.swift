//
//  PublicProfileUpdateDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

// Updates DTO for push operations (minimal fields for conflict resolution).
public struct PublicProfileUpdateDTO: Codable, Sendable, Equatable {
    public let username: String?
    public let avatarURL: String?
    public let displayName: String
    public let bio: String?
    public let ageYears: Int?
    public let gender: String?
    public let isVerified: Bool
    public let updatedAt: Date
    public let idempotencyKey: String
    
    public init(
        username: String?,
        avatarURL: String?,
        displayName: String,
        bio: String?,
        ageYears: Int?,
        gender: String?,
        isVerified: Bool,
        updatedAt: Date,
        idempotencyKey: String
    ) {
        self.username = username
        self.avatarURL = avatarURL
        self.displayName = displayName
        self.bio = bio
        self.ageYears = ageYears
        self.gender = gender
        self.isVerified = isVerified
        self.updatedAt = updatedAt
        self.idempotencyKey = idempotencyKey
    }
    
    // Creates from LocalPublicProfilePending and PublicProfileDTO.
    public static func from(local: LocalPublicProfilePending, dto: PublicProfileDTO) -> PublicProfileUpdateDTO {
        PublicProfileUpdateDTO(
            username: dto.username,
            avatarURL: dto.avatarURL,
            displayName: dto.displayName,
            bio: dto.bio,
            ageYears: dto.ageYears,
            gender: dto.gender,
            isVerified: dto.isVerified,
            updatedAt: dto.updatedAt,
            idempotencyKey: local.idempotencyKey
        )
    }
}

