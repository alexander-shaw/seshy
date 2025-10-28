//
//  H3AggregatedNode.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// Stored locally.  Aggregate immediately.

import Foundation
import CoreData
import CoreLocation
import H3
import CoreDomain

@objc(H3AggregatedNode)
public class H3AggregatedNode: NSManagedObject {}

public extension H3AggregatedNode {
    @nonobjc class func fetchRequest() -> NSFetchRequest<H3AggregatedNode> {
        NSFetchRequest<H3AggregatedNode>(entityName: "H3AggregatedNode")
    }

    @NSManaged var id: String  // MARK: Unique (h3Index + motionType).
    @NSManaged var motionTypeRaw: Int16
    @NSManaged var resolution: Int16
    @NSManaged var h3Index: Int64  // MARK: Unique and indexed.

    @NSManaged var firstVisitedAt: Date
    @NSManaged var lastVisitedAt: Date
    @NSManaged var visitCount: Int64
}

public extension H3AggregatedNode {
    var motionType: MotionType {
        get { MotionType(rawValue: motionTypeRaw) ?? .unknown }
        set { motionTypeRaw = newValue.rawValue }
    }
}

// Local & Cloud Storage:
extension H3AggregatedNode: SyncTrackable {
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
