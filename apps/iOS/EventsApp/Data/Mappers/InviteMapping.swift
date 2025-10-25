//
//  InviteMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapInviteToDTO(_ obj: Invite) -> InviteDTO {
    InviteDTO(
        id: obj.id,
        userID: obj.userID,
        typeRaw: obj.typeRaw,
        statusRaw: obj.statusRaw,
        token: obj.token,
        expiresAt: obj.expiresAt,
        eventID: obj.event.id,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
        deletedAt: obj.deletedAt,
        syncStatusRaw: obj.syncStatusRaw,
        lastCloudSyncedAt: obj.lastCloudSyncedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension Invite {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: InviteDTO) {
        id = dto.id
        userID = dto.userID
        typeRaw = dto.typeRaw
        statusRaw = dto.statusRaw
        token = dto.token
        expiresAt = dto.expiresAt
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        syncStatusRaw = dto.syncStatusRaw
        lastCloudSyncedAt = dto.lastCloudSyncedAt
        // Event relationship handled separately.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: InviteDTO, event: UserEvent) -> Invite {
        let obj = Invite(context: ctx)
        obj.apply(dto)
        obj.event = event
        return obj
    }
}
