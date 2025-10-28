//
//  H3AggregatedEdge.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// Stored locally.  Aggregate immediately.

import Foundation
import CoreData
import CoreLocation
import H3
import CoreDomain

@objc(H3AggregatedEdge)
public class H3AggregatedEdge: NSManagedObject {}

public extension H3AggregatedEdge {
    @nonobjc class func fetchRequest() -> NSFetchRequest<H3AggregatedEdge> {
        NSFetchRequest<H3AggregatedEdge>(entityName: "H3AggregatedEdge")
    }

    @NSManaged var id: String  // MARK: Unique (fromHexIndex + toHexIndex + motionTypeRaw).
    @NSManaged var fromHexIndex: Int64
    @NSManaged var toHexIndex: Int64
    @NSManaged var motionTypeRaw: Int16

    // Coverage.
    @NSManaged var firstTraversedAt: Date
    @NSManaged var lastTraversedAt: Date
    @NSManaged var traverseCount: Int64

    // Always-present aggregates (safe to average).
    @NSManaged var sumTime: Double
    @NSManaged var maxTime: Double
    @NSManaged var minTime: Double

    @NSManaged var sumDistance: Double
    @NSManaged var maxDistance: Double
    @NSManaged var minDistance: Double

    // Elevation.
    @NSManaged var sumElevationDelta: NSNumber?
    @NSManaged var maxElevationDelta: NSNumber?
    @NSManaged var minElevationDelta: NSNumber?
    @NSManaged var elevationSamples: Int64
}

extension H3AggregatedEdge {
    public var motionType: MotionType {
        get { MotionType(rawValue: motionTypeRaw) ?? .unknown }
        set { motionTypeRaw = newValue.rawValue }
    }

    public var averageTime: Double? {
        return traverseCount > 0 ? (sumTime / Double(traverseCount)) : nil
    }

    public var averageDistance: Double? {
        return traverseCount > 0 ? (sumDistance / Double(traverseCount)) : nil
    }

    public var averageSpeed: Double? {
        return sumTime > 0 ? (sumDistance / sumTime) : nil
    }

    public var averageElevationDelta: Double? {
        guard let sum = sumElevationDelta, elevationSamples > 0 else { return nil }
        return Double(truncating: sum) / Double(elevationSamples)
    }
}

// Local & Cloud Storage:
extension H3AggregatedEdge: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var schemaVersion: Int16

    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
