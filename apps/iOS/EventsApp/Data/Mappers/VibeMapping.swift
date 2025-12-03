//
//  VibeMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

// Provides mapping functions between Core Data Vibe entities and TagDTOs.
// Used for converting between local storage format and transport/cloud format.

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapVibeToDTO(_ obj: Vibe) -> VibeDTO {
    VibeDTO(
        id: obj.id,
        name: obj.name,
        slug: obj.slug,
        categoryRaw: obj.categoryRaw,
        systemDefined: obj.systemDefined,
        isActive: obj.isActive,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
        deletedAt: obj.deletedAt,
        syncStatusRaw: obj.syncStatusRaw,
        lastCloudSyncedAt: obj.lastCloudSyncedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension Vibe {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: VibeDTO) {
        id = dto.id
        name = dto.name
        slug = dto.slug
        categoryRaw = dto.categoryRaw
        systemDefined = dto.systemDefined
        isActive = dto.isActive
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        syncStatusRaw = dto.syncStatusRaw
        lastCloudSyncedAt = dto.lastCloudSyncedAt
        schemaVersion = Int16(dto.schemaVersion)
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: VibeDTO) -> Vibe {
        let obj = Vibe(context: ctx)
        obj.apply(dto)
        return obj
    }
}
