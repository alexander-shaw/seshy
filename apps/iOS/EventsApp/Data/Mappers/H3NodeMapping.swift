//
//  H3NodeMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapH3NodeToDTO(_ obj: H3Node) -> H3NodeDTO {
    H3NodeDTO(
        id: obj.id,
        timestamp: obj.timestamp,
        horizontalAccuracy: obj.horizontalAccuracy?.doubleValue,
        altitude: obj.altitude?.doubleValue,
        verticalAccuracy: obj.verticalAccuracy?.doubleValue,
        speed: obj.speed?.doubleValue,
        speedAccuracy: obj.speedAccuracy?.doubleValue,
        course: obj.course?.doubleValue,
        courseAccuracy: obj.courseAccuracy?.doubleValue,
        motionTypeRaw: obj.motionTypeRaw,
        resolution: obj.resolution,
        h3Index: obj.h3Index,
        updatedAt: obj.updatedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension H3Node {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: H3NodeDTO) {
        id = dto.id
        timestamp = dto.timestamp
        horizontalAccuracy = dto.horizontalAccuracy.map { NSNumber(value: $0) }
        altitude = dto.altitude.map { NSNumber(value: $0) }
        verticalAccuracy = dto.verticalAccuracy.map { NSNumber(value: $0) }
        speed = dto.speed.map { NSNumber(value: $0) }
        speedAccuracy = dto.speedAccuracy.map { NSNumber(value: $0) }
        course = dto.course.map { NSNumber(value: $0) }
        courseAccuracy = dto.courseAccuracy.map { NSNumber(value: $0) }
        motionTypeRaw = dto.motionTypeRaw
        resolution = dto.resolution
        h3Index = dto.h3Index
        updatedAt = dto.updatedAt
        // createdAt / deletedAt / syncStatus handled by your sync flow.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: H3NodeDTO) -> H3Node {
        let obj = H3Node(context: ctx)
        obj.apply(dto)
        return obj
    }
}
