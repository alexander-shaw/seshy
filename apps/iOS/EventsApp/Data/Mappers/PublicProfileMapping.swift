//
//  PublicProfileMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapPublicProfileToDTO(_ obj: PublicProfile) -> PublicProfileDTO {
    PublicProfileDTO(
        id: obj.id,
        avatarURL: obj.avatarURL,
        username: obj.username,
        displayName: obj.displayName,
        bio: obj.bio,
        ageYears: obj.ageYears?.intValue,
        gender: obj.gender,
        isVerified: obj.isVerified,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
        deletedAt: obj.deletedAt,
        syncStatusRaw: obj.syncStatusRaw,
        lastCloudSyncedAt: obj.lastCloudSyncedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension PublicProfile {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: PublicProfileDTO) {
        id = dto.id
        avatarURL = dto.avatarURL
        username = dto.username
        displayName = dto.displayName
        bio = dto.bio
        ageYears = dto.ageYears.map { NSNumber(value: $0) }
        gender = dto.gender
        isVerified = dto.isVerified
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        syncStatusRaw = dto.syncStatusRaw
        lastCloudSyncedAt = dto.lastCloudSyncedAt
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: PublicProfileDTO) -> PublicProfile {
        let obj = PublicProfile(context: ctx)
        obj.apply(dto)
        return obj
    }
}
