//
//  UserEventMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapUserEventToDTO(_ obj: UserEvent) -> UserEventDTO {
    UserEventDTO(
        id: obj.id,
        scheduleStatusRaw: obj.scheduleStatusRaw,
        name: obj.name,
        details: obj.details,
        brandColor: obj.brandColor,
        startTime: obj.startTime,
        endTime: obj.endTime,
        durationMinutes: obj.durationMinutes?.int64Value,
        locationID: obj.location?.id ?? {
            fatalError("Data integrity issue: UserEvent must have a location.")
        }(),
        maxCapacity: obj.maxCapacity,
        visibilityRaw: obj.visibilityRaw,
        inviteLink: obj.inviteLink,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
        deletedAt: obj.deletedAt,
        syncStatusRaw: obj.syncStatusRaw,
        lastCloudSyncedAt: obj.lastCloudSyncedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension UserEvent {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: UserEventDTO) {
        id = dto.id
        scheduleStatusRaw = dto.scheduleStatusRaw
        name = dto.name
        details = dto.details
        brandColor = dto.brandColor
        startTime = dto.startTime
        endTime = dto.endTime
        durationMinutes = dto.durationMinutes.map { NSNumber(value: $0) }
        maxCapacity = dto.maxCapacity
        visibilityRaw = dto.visibilityRaw
        inviteLink = dto.inviteLink
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        syncStatusRaw = dto.syncStatusRaw
        lastCloudSyncedAt = dto.lastCloudSyncedAt
        // Location relationship handled separately.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: UserEventDTO, location: Place) -> UserEvent {
        let obj = UserEvent(context: ctx)
        obj.apply(dto)
        obj.location = location
        return obj
    }
}
