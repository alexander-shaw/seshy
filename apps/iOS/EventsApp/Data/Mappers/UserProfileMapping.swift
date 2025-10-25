//
//  UserProfileMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapUserProfileToDTO(_ obj: UserProfile) -> UserProfileDTO {
    UserProfileDTO(
        id: obj.id,
        displayName: obj.displayName,
        bio: obj.bio,
        dateOfBirth: obj.dateOfBirth,
        showAge: obj.showAge,
        genderCategoryRaw: obj.genderCategoryRaw?.int16Value,
        genderIdentity: obj.genderIdentity,
        showGender: obj.showGender,
        isVerified: obj.isVerified,
        wasVerifiedAt: obj.wasVerifiedAt,
        updatedAt: obj.updatedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension UserProfile {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: UserProfileDTO) {
        id = dto.id
        displayName = dto.displayName
        bio = dto.bio
        dateOfBirth = dto.dateOfBirth
        showAge = dto.showAge
        genderCategoryRaw = dto.genderCategoryRaw.map { NSNumber(value: $0) }
        genderIdentity = dto.genderIdentity
        showGender = dto.showGender
        isVerified = dto.isVerified
        wasVerifiedAt = dto.wasVerifiedAt
        updatedAt = dto.updatedAt
        // createdAt / deletedAt / syncStatus handled by your sync flow.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: UserProfileDTO) -> UserProfile {
        let obj = UserProfile(context: ctx)
        obj.apply(dto)
        return obj
    }
}
