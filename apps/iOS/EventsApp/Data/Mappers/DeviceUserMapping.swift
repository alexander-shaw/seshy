//
//  DeviceUserMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapDeviceUserToDTO(_ obj: DeviceUser) -> DeviceUserDTO {
    DeviceUserDTO(
        id: obj.id,
        username: obj.username,
        updatedAt: obj.updatedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension DeviceUser {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: DeviceUserDTO) {
        id = dto.id
        username = dto.username
        updatedAt = dto.updatedAt
        // createdAt / deletedAt / syncStatus handled by your sync flow.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: DeviceUserDTO) -> DeviceUser {
        let obj = DeviceUser(context: ctx)
        obj.apply(dto)
        return obj
    }
}
