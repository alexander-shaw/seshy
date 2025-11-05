//
//  Place.swift
//  EventsApp
//
//  Created by Шоу on 10/6/25.
//

// Human-readable location for a UserEvent.  A reusable venue/address with coordinates.

import Foundation
import CoreData
import CoreDomain

@objc(Place)
public class Place: NSManagedObject {}

extension Place {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Place> {
        NSFetchRequest<Place>(entityName: "Place")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var radius: Double

    @NSManaged public var name: String
    @NSManaged public var details: String?
    @NSManaged public var maxCapacity: NSNumber?  // Nil means infinite (not strictly defined).

    @NSManaged public var roomNumber: String?
    @NSManaged public var streetAddress: String?
    @NSManaged public var city: String?
    @NSManaged public var stateRegion: String?

    // Relationships:
    @NSManaged public var events: Set<EventItem>?
}

// Local & Cloud Storage:
extension Place: SyncTrackable {
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
