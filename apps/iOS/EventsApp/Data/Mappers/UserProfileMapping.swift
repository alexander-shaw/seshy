//
//  UserProfileMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData
import CoreDomain

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
    // Applies values from a DTO (call inside the context's perform block).
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
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: UserProfileDTO) -> UserProfile {
        let obj = UserProfile(context: ctx)
        obj.apply(dto)
        return obj
    }
}

// MARK: - CONFLICT RESOLUTION:
// Upserts profile with conflict resolution.
public func upsertProfile(
    from dto: UserProfileDTO,
    policy: ConflictRule,
    in ctx: NSManagedObjectContext,
    user: DeviceUser
) throws {
    // Finds existing profile by ID or by user relationship.
    let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@ OR user == %@", dto.id as CVarArg, user)
    request.fetchLimit = 1
    
    let existing = try ctx.fetch(request).first
    
    if let existing = existing {
        // Updates existing with conflict resolution.
        switch policy {
        case .serverWins:
            // Always uses server values.
            existing.apply(dto)
            existing.createdAt = existing.createdAt  // Preserves original createdAt.
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
            // Compares updatedAt timestamps.
            if dto.updatedAt >= existing.updatedAt {
                // Server is newer or equal, use server values.
                existing.apply(dto)
                existing.createdAt = existing.createdAt  // Preserves original createdAt.
            }
            // If client is newer, keep existing values.
            existing.lastCloudSyncedAt = Date()
            existing.syncStatus = .synced
        }
    } else {
        // Creates new profile.
        let profile = UserProfile(context: ctx)
        profile.id = dto.id
        profile.apply(dto)
        profile.createdAt = Date()
        profile.user = user
        profile.lastCloudSyncedAt = Date()
        profile.syncStatus = .synced
        profile.schemaVersion = 1
    }
}
