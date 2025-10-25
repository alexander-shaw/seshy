//
//  MediaMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapEventMediaToDTO(_ obj: EventMedia) -> EventMediaDTO {
    EventMediaDTO(
        id: obj.id,
        url: obj.url,
        position: obj.position,
        mimeType: obj.mimeType,
        averageColorHex: obj.averageColorHex,
        eventID: obj.event.id,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
        deletedAt: obj.deletedAt,
        syncStatusRaw: obj.syncStatusRaw,
        lastCloudSyncedAt: obj.lastCloudSyncedAt,
        schemaVersion: 1
    )
}

@inline(__always)
public func mapUserMediaToDTO(_ obj: UserMedia) -> UserMediaDTO {
    UserMediaDTO(
        id: obj.id,
        url: obj.url,
        position: obj.position,
        mimeType: obj.mimeType,
        averageColorHex: obj.averageColorHex,
        ownerProfileID: obj.ownerProfile.id,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
        deletedAt: obj.deletedAt,
        syncStatusRaw: obj.syncStatusRaw,
        lastCloudSyncedAt: obj.lastCloudSyncedAt,
        schemaVersion: 1
    )
}

@inline(__always)
public func mapProfileMediaToDTO(_ obj: ProfileMedia) -> ProfileMediaDTO {
    ProfileMediaDTO(
        id: obj.id,
        url: obj.url,
        position: obj.position,
        mimeType: obj.mimeType,
        averageColorHex: obj.averageColorHex,
        profileID: obj.profile.id,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
        deletedAt: obj.deletedAt,
        syncStatusRaw: obj.syncStatusRaw,
        lastCloudSyncedAt: obj.lastCloudSyncedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension EventMedia {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: EventMediaDTO) {
        id = dto.id
        url = dto.url
        position = dto.position
        mimeType = dto.mimeType
        averageColorHex = dto.averageColorHex
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        syncStatusRaw = dto.syncStatusRaw
        lastCloudSyncedAt = dto.lastCloudSyncedAt
        // Event relationship handled separately.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: EventMediaDTO, event: UserEvent) -> EventMedia {
        let obj = EventMedia(context: ctx)
        obj.apply(dto)
        obj.event = event
        return obj
    }
}

extension UserMedia {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: UserMediaDTO) {
        id = dto.id
        url = dto.url
        position = dto.position
        mimeType = dto.mimeType
        averageColorHex = dto.averageColorHex
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        syncStatusRaw = dto.syncStatusRaw
        lastCloudSyncedAt = dto.lastCloudSyncedAt
        // OwnerProfile relationship handled separately.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: UserMediaDTO, profile: UserProfile) -> UserMedia {
        let obj = UserMedia(context: ctx)
        obj.apply(dto)
        obj.ownerProfile = profile
        return obj
    }
}

extension ProfileMedia {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: ProfileMediaDTO) {
        id = dto.id
        url = dto.url
        position = dto.position
        mimeType = dto.mimeType
        averageColorHex = dto.averageColorHex
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        syncStatusRaw = dto.syncStatusRaw
        lastCloudSyncedAt = dto.lastCloudSyncedAt
        // Profile relationship handled separately.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: ProfileMediaDTO, profile: PublicProfile) -> ProfileMedia {
        let obj = ProfileMedia(context: ctx)
        obj.apply(dto)
        obj.profile = profile
        return obj
    }
}
