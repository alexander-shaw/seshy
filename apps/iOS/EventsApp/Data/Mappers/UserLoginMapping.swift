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
        lastLoginAt = dto.lastLoginAt
        phoneE164Hashed = dto.phoneE164Hashed
        phoneVerifiedAt = dto.phoneVerifiedAt
        emailAddressHashed = dto.emailAddressHashed
        emailDomain = dto.emailDomain
        emailVerifiedAt = dto.emailVerifiedAt
        updatedAt = dto.updatedAt
        // createdAt / deletedAt / syncStatus handled by your sync flow.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: UserLoginDTO) -> UserLogin {
        let obj = UserLogin(context: ctx)
        obj.apply(dto)
        return obj
    }
}
