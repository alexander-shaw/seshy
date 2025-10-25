//
//  H3Edge.swift
//  EventsApp
//
//  Created by Шоу on 10/13/25.
//

// Represents a traversal or transition between two H3 nodes.
// Retained locally for up to 30 days and then purged automatically.
// Raw edge data is uploaded in compressed batch files for aggregation and analysis.

import Foundation
import CoreData
import CoreLocation
import H3
import CoreDomain

@objc(H3Edge)
public class H3Edge: NSManagedObject {}

public extension H3Edge {
    @nonobjc class func fetchRequest() -> NSFetchRequest<H3Edge> {
        NSFetchRequest<H3Edge>(entityName: "H3Edge")
    }

    @NSManaged var id: UUID
    @NSManaged var timestamp: Date
    @NSManaged var fromHexIndex: Int64
    @NSManaged var toHexIndex: Int64
    @NSManaged var motionTypeRaw: Int16

    // Deltas (always present):
    @NSManaged var deltaTime: Double
    @NSManaged var deltaDistance: Double

    // Deltas (may be absent):
    @NSManaged var deltaAltitude: NSNumber?  // Optional Double.
    @NSManaged var deltaSpeed: NSNumber?  // Optional Double.
    @NSManaged var deltaCourse: NSNumber?  // Optional Double.
    @NSManaged var deltaFloor: NSNumber?  // Optional Double.
}

public extension H3Edge {
    var motionType: MotionType {
        get { MotionType(rawValue: motionTypeRaw) ?? .unknown }
        set { motionTypeRaw = newValue.rawValue }
    }
}

// Local & Cloud Storage:
extension H3Edge: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var schemaVersion: Int

    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
