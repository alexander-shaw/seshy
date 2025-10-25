//
//  H3AggregatedEdgeMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapH3AggregatedEdgeToDTO(_ obj: H3AggregatedEdge) -> H3AggregatedEdgeDTO {
    H3AggregatedEdgeDTO(
        id: obj.id,
        fromHexIndex: obj.fromHexIndex,
        toHexIndex: obj.toHexIndex,
        motionTypeRaw: obj.motionTypeRaw,
        firstTraversedAt: obj.firstTraversedAt,
        lastTraversedAt: obj.lastTraversedAt,
        traverseCount: obj.traverseCount,
        sumTime: obj.sumTime,
        maxTime: obj.maxTime,
        minTime: obj.minTime,
        sumDistance: obj.sumDistance,
        maxDistance: obj.maxDistance,
        minDistance: obj.minDistance,
        sumElevationDelta: obj.sumElevationDelta?.doubleValue,
        maxElevationDelta: obj.maxElevationDelta?.doubleValue,
        minElevationDelta: obj.minElevationDelta?.doubleValue,
        elevationSamples: obj.elevationSamples,
        updatedAt: obj.updatedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension H3AggregatedEdge {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: H3AggregatedEdgeDTO) {
        id = dto.id
        fromHexIndex = dto.fromHexIndex
        toHexIndex = dto.toHexIndex
        motionTypeRaw = dto.motionTypeRaw
        firstTraversedAt = dto.firstTraversedAt
        lastTraversedAt = dto.lastTraversedAt
        traverseCount = dto.traverseCount
        sumTime = dto.sumTime
        maxTime = dto.maxTime
        minTime = dto.minTime
        sumDistance = dto.sumDistance
        maxDistance = dto.maxDistance
        minDistance = dto.minDistance
        sumElevationDelta = dto.sumElevationDelta.map { NSNumber(value: $0) }
        maxElevationDelta = dto.maxElevationDelta.map { NSNumber(value: $0) }
        minElevationDelta = dto.minElevationDelta.map { NSNumber(value: $0) }
        elevationSamples = dto.elevationSamples
        updatedAt = dto.updatedAt
        // createdAt / deletedAt / syncStatus handled by your sync flow.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: H3AggregatedEdgeDTO) -> H3AggregatedEdge {
        let obj = H3AggregatedEdge(context: ctx)
        obj.apply(dto)
        return obj
    }
}
