//
//  MediaMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/29/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapMediaToDTO(_ obj: Media) -> MediaDTO {
    // Determine which owner ID to include.
    var eventID: UUID? = nil
    var userProfileID: UUID? = nil
    var publicProfileID: UUID? = nil
    
    if let event = obj.event {
        eventID = event.id
    } else if let userProfile = obj.userProfile {
        userProfileID = userProfile.id
    } else if let publicProfile = obj.publicProfile {
        publicProfileID = publicProfile.id
    }
    
    return MediaDTO(
        id: obj.id,
        url: obj.url,
        position: obj.position,
        mimeType: obj.mimeType,
        averageColorHex: obj.averageColorHex,
        eventID: eventID,
        userProfileID: userProfileID,
        publicProfileID: publicProfileID,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
        deletedAt: obj.deletedAt,
        syncStatusRaw: obj.syncStatusRaw,
        lastCloudSyncedAt: obj.lastCloudSyncedAt,
        schemaVersion: Int(obj.schemaVersion)
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension Media {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: MediaDTO) {
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
        schemaVersion = Int16(dto.schemaVersion)
        // Owner relationships handled separately via insert methods.
    }
    
    // Convenience for inserting new managed object from DTO with event owner.
    static func insert(into ctx: NSManagedObjectContext, from dto: MediaDTO, event: EventItem) -> Media {
        let obj = Media(context: ctx)
        obj.apply(dto)
        obj.event = event
        obj.userProfile = nil
        obj.publicProfile = nil
        return obj
    }
    
    // Convenience for inserting new managed object from DTO with userProfile owner.
    static func insert(into ctx: NSManagedObjectContext, from dto: MediaDTO, userProfile: UserProfile) -> Media {
        let obj = Media(context: ctx)
        obj.apply(dto)
        obj.userProfile = userProfile
        obj.event = nil
        obj.publicProfile = nil
        return obj
    }
    
    // Convenience for inserting new managed object from DTO with publicProfile owner.
    static func insert(into ctx: NSManagedObjectContext, from dto: MediaDTO, publicProfile: PublicProfile) -> Media {
        let obj = Media(context: ctx)
        obj.apply(dto)
        obj.publicProfile = publicProfile
        obj.event = nil
        obj.userProfile = nil
        return obj
    }
}
