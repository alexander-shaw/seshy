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

// MARK: - CONFLICT RESOLUTION:
// Upsert PublicProfile with conflict resolution.
public func upsertPublicProfile(
    from dto: PublicProfileDTO,
    policy: ConflictRule,
    in ctx: NSManagedObjectContext,
    user: DeviceUser
) throws {
    // Find existing PublicProfile by ID or by user relationship.
    let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@ OR userProfile.user == %@", dto.id as CVarArg, user)
    request.fetchLimit = 1
    
    let existing = try ctx.fetch(request).first
    
    if let existing = existing {
        // Update existing with conflict resolution.
        switch policy {
        case .serverWins:
            // Always use server values.
            existing.apply(dto)
            existing.createdAt = existing.createdAt  // Preserve original createdAt.
            existing.lastCloudSyncedAt = Date()
            existing.syncStatus = .synced
            
        case .clientWins:
            // Keep existing values if conflict detected.
            if existing.updatedAt > dto.updatedAt {
                // Client is newer, keep existing.
                existing.lastCloudSyncedAt = Date()
                existing.syncStatus = .synced
            } else {
                // Server is newer or equal, but policy says client wins - keep existing.
                existing.lastCloudSyncedAt = Date()
                existing.syncStatus = .synced
            }
            
        case .lastWriteWins:
            // Compare updatedAt timestamps.
            if dto.updatedAt >= existing.updatedAt {
                // Server is newer or equal, use server values.
                existing.apply(dto)
                existing.createdAt = existing.createdAt  // Preserve original createdAt.
            }
            // If client is newer, keep existing values.
            existing.lastCloudSyncedAt = Date()
            existing.syncStatus = .synced
        }
    } else {
        // Create new PublicProfile.
        let profile = PublicProfile(context: ctx)
        profile.id = dto.id
        profile.apply(dto)
        profile.createdAt = Date()
        
        // Try to find associated UserProfile.
        let userProfileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        userProfileRequest.predicate = NSPredicate(format: "id == %@ OR user == %@", dto.id as CVarArg, user)
        userProfileRequest.fetchLimit = 1
        if let userProfile = try ctx.fetch(userProfileRequest).first {
            profile.userProfile = userProfile
            userProfile.publicProfile = profile
        }
        
        profile.lastCloudSyncedAt = Date()
        profile.syncStatus = .synced
        profile.schemaVersion = 1
    }
}
