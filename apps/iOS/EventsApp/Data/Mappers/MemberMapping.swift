//
//  MemberMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapMemberToDTO(_ obj: Member) -> MemberDTO {
    MemberDTO(
        id: obj.id,
        roleRaw: obj.roleRaw,
        userID: obj.userID,
        displayName: obj.displayName,
        username: obj.username,
        avatarURL: obj.avatarURL,
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
extension Member {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: MemberDTO) {
        id = dto.id
        roleRaw = dto.roleRaw
        userID = dto.userID
        displayName = dto.displayName
        username = dto.username
        avatarURL = dto.avatarURL
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        syncStatusRaw = dto.syncStatusRaw
        lastCloudSyncedAt = dto.lastCloudSyncedAt
        // Event relationship handled separately.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: MemberDTO, event: UserEvent) -> Member {
        let obj = Member(context: ctx)
        obj.apply(dto)
        obj.event = event
        return obj
    }
}
