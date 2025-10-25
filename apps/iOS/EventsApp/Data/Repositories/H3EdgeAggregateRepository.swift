//
//  H3EdgeAggregateRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/12/25.
//

import Foundation
import CoreData
import H3
import CoreDomain

public protocol H3EdgeAggregateRepository: Sendable {
    func upsert(from: Int64, to: Int64, motion: MotionType, deltaT: Double, deltaD: Double, deltaE: Double, now: Date) async throws -> H3AggregatedEdgeDTO
    func getAggregatedEdges(for motionType: MotionType?) async throws -> [H3AggregatedEdgeDTO]
    func getAggregatedEdge(id: String) async throws -> H3AggregatedEdgeDTO?
}

final class CoreDataH3EdgeAggregateRepository: H3EdgeAggregateRepository {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    func upsert(from: Int64, to: Int64, motion: MotionType, deltaT: Double, deltaD: Double, deltaE: Double, now: Date = .now) async throws -> H3AggregatedEdgeDTO {
        return try await coreDataStack.performBackgroundTask { context in
            let req: NSFetchRequest<H3AggregatedEdge> = H3AggregatedEdge.fetchRequest()
            req.predicate = NSPredicate(format: "fromHexIndex == %@ AND toHexIndex == %@ AND motionTypeRaw == %d", NSNumber(value: from), NSNumber(value: to), motion.rawValue)

            let agg = try context.fetch(req).first ?? {
                let a = H3AggregatedEdge(context: context)
                a.id = "\(from)-\(to)-\(motion.rawValue)"
                a.fromHexIndex = from
                a.toHexIndex = to
                a.motionTypeRaw = motion.rawValue
                a.firstTraversedAt = now
                a.createdAt = now
                a.updatedAt = now
                a.lastTraversedAt = now
                a.syncStatusRaw = SyncStatus.pending.rawValue
                a.traverseCount = 0
                a.sumTime = 0
                a.sumDistance = 0
                a.maxTime = 0
                a.minTime = Double.infinity
                a.maxDistance = 0
                a.minDistance = Double.infinity
                a.elevationSamples = 0
                return a
            }()

            agg.traverseCount += 1
            agg.sumTime += deltaT
            agg.sumDistance += deltaD
            
            // Update min/max time.
            agg.maxTime = max(agg.maxTime, deltaT)
            agg.minTime = min(agg.minTime, deltaT)
            
            // Update min/max distance.
            agg.maxDistance = max(agg.maxDistance, deltaD)
            agg.minDistance = min(agg.minDistance, deltaD)
            
            // Handle elevation delta safely.
            if let currentElevation = agg.sumElevationDelta {
                let newElevation = currentElevation.doubleValue + deltaE
                agg.sumElevationDelta = NSNumber(value: newElevation)
                agg.maxElevationDelta = NSNumber(value: max(agg.maxElevationDelta?.doubleValue ?? Double.leastNormalMagnitude, newElevation))
                agg.minElevationDelta = NSNumber(value: min(agg.minElevationDelta?.doubleValue ?? Double.greatestFiniteMagnitude, newElevation))
            } else {
                agg.sumElevationDelta = NSNumber(value: deltaE)
                agg.maxElevationDelta = NSNumber(value: deltaE)
                agg.minElevationDelta = NSNumber(value: deltaE)
            }
            
            agg.elevationSamples += 1
            agg.lastTraversedAt = now
            agg.updatedAt = now
            agg.syncStatusRaw = SyncStatus.pending.rawValue

            try context.save()
            return mapH3AggregatedEdgeToDTO(agg)
        }
    }

    func getAggregatedEdges(for motionType: MotionType? = nil) async throws -> [H3AggregatedEdgeDTO] {
        return try await coreDataStack.performBackgroundTask { context in
            let req: NSFetchRequest<H3AggregatedEdge> = H3AggregatedEdge.fetchRequest()
            
            if let motionType = motionType {
                req.predicate = NSPredicate(format: "motionTypeRaw == %d", motionType.rawValue)
            }
            
            req.sortDescriptors = [NSSortDescriptor(key: "lastTraversedAt", ascending: false)]
            
            let edges = try context.fetch(req)
            return edges.map(mapH3AggregatedEdgeToDTO)
        }
    }

    func getAggregatedEdge(id: String) async throws -> H3AggregatedEdgeDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let req: NSFetchRequest<H3AggregatedEdge> = H3AggregatedEdge.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@", id)
            req.fetchLimit = 1
            
            guard let edge = try context.fetch(req).first else { return nil }
            return mapH3AggregatedEdgeToDTO(edge)
        }
    }
}
