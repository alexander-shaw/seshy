//
//  UserLoginMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapUserLoginToDTO(_ obj: UserLogin) -> UserLoginDTO {
    UserLoginDTO(
        id: obj.id,
        lastLoginAt: obj.lastLoginAt,
        phoneE164Hashed: obj.phoneE164Hashed,
        phoneVerifiedAt: obj.phoneVerifiedAt,
        emailAddressHashed: obj.emailAddressHashed,
        emailDomain: obj.emailDomain,
        emailVerifiedAt: obj.emailVerifiedAt,
        updatedAt: obj.updatedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension UserLogin {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: UserLoginDTO) {
        id = dto.id
        // TODO: Add lastLoginAt.
        phoneE164Hashed = dto.phoneE164Hashed  // Synced for contact matching.
        phoneVerifiedAt = dto.phoneVerifiedAt
        emailAddressHashed = dto.emailAddressHashed  // Synced for contact matching.
        emailVerifiedAt = dto.emailVerifiedAt
        updatedAt = dto.updatedAt
    }
    
    // Apply only synced fields (for pull operations - preserves local-only fields).
    func applySyncedFields(from dto: UserLoginDTO) {
        id = dto.id
        phoneE164Hashed = dto.phoneE164Hashed  // For contact matching.
        phoneVerifiedAt = dto.phoneVerifiedAt
        emailAddressHashed = dto.emailAddressHashed  // For contact matching.
        emailVerifiedAt = dto.emailVerifiedAt
        updatedAt = dto.updatedAt
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: UserLoginDTO) -> UserLogin {
        let obj = UserLogin(context: ctx)
        obj.apply(dto)
        return obj
    }
}

// MARK: - CONFLICT RESOLUTION:
// Upserts login with conflict resolution.
public func upsertLogin(
    from dto: UserLoginDTO,
    policy: ConflictRule,
    in ctx: NSManagedObjectContext,
    user: DeviceUser
) throws {
    // Finds existing login by ID or by user relationship.
    let request: NSFetchRequest<UserLogin> = UserLogin.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@ OR user == %@", dto.id as CVarArg, user)
    request.fetchLimit = 1
    
    let existing = try ctx.fetch(request).first
    
    if let existing = existing {
        // Updates existing with conflict resolution.
        switch policy {
        case .serverWins:
            // Always uses server values for synced fields (preserve local-only fields).
            existing.applySyncedFields(from: dto)
            existing.createdAt = existing.createdAt  // Preserves original createdAt.
            existing.lastCloudSyncedAt = Date()
            existing.syncStatus = .synced
            
        case .clientWins:
            // Keeps existing values if conflict detected (preserves local-only fields).
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
            // Compares updatedAt timestamps (preserve local-only fields).
            if dto.updatedAt >= existing.updatedAt {
                // Server is newer or equal, use server values for synced fields.
                existing.applySyncedFields(from: dto)
                existing.createdAt = existing.createdAt  // Preserves original createdAt.
            }
            // If client is newer, keep existing values.
            existing.lastCloudSyncedAt = Date()
            existing.syncStatus = .synced
        }
    } else {
        // Creates new login.
        let login = UserLogin(context: ctx)
        login.id = dto.id
        login.applySyncedFields(from: dto)  // Applies only synced fields.
        login.createdAt = Date()
        login.user = user
        login.lastCloudSyncedAt = Date()
        login.syncStatus = .synced
        login.schemaVersion = 1
    }
}
