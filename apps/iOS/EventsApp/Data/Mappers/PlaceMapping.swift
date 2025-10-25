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
        details: obj.details,
        streetAddress: obj.streetAddress,
        city: obj.city,
        stateRegion: obj.stateRegion,
        roomNumber: obj.roomNumber,
        latitude: obj.latitude,
        longitude: obj.longitude,
        radius: obj.radius,
        updatedAt: obj.updatedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension Place {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: PlaceDTO) {
        id = dto.id
        name = dto.name
        details = dto.details
        streetAddress = dto.streetAddress
        city = dto.city
        stateRegion = dto.stateRegion
        roomNumber = dto.roomNumber
        latitude = dto.latitude
        longitude = dto.longitude
        radius = dto.radius
        updatedAt = dto.updatedAt
        // createdAt / deletedAt / syncStatus handled by your sync flow.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: PlaceDTO) -> Place {
        let obj = Place(context: ctx)
        obj.apply(dto)
        return obj
    }
}
