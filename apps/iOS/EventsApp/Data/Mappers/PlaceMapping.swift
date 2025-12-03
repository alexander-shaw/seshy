//
//  PlaceMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapPlaceToDTO(_ obj: Place) -> PlaceDTO {
    PlaceDTO(
        id: obj.id,
        name: obj.name,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
        deletedAt: obj.deletedAt,
        syncStatusRaw: obj.syncStatusRaw,
        lastCloudSyncedAt: obj.lastCloudSyncedAt,
        schemaVersion: obj.schemaVersion
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension Place {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: PlaceDTO) {
        id = dto.id
        name = dto.name
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        syncStatusRaw = dto.syncStatusRaw
        lastCloudSyncedAt = dto.lastCloudSyncedAt
        schemaVersion = dto.schemaVersion
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: PlaceDTO) -> Place {
        let obj = Place(context: ctx)
        obj.apply(dto)
        return obj
    }
}
