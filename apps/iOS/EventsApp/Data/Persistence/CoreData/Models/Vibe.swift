//
//  Vibe.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// This file defines the Core Data entity for tags that categorize UserEvents and Users.
// Vibes can be system-defined or user-created and are used for filtering and discovery.
// Top users and subscribers could unlock a feature for creating these.  User-created tags are not used for ML.

import Foundation
import CoreData
import CoreDomain

@objc(Vibe)
public class Vibe: NSManagedObject {}

extension Vibe {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Vibe> {
        NSFetchRequest<Vibe>(entityName: "Vibe")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var slug: String  // MARK: Unique and indexed.
    @NSManaged public var categoryRaw: Int16  // VibeCategory.
    @NSManaged public var systemDefined: Bool  // Can be user-created.
    @NSManaged public var isActive: Bool  // Do not display if not active.

    // Relationships:
    @NSManaged public var events: Set<EventItem>
}

extension Vibe {
    public var category: VibeCategory {
        get { VibeCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }
}

// Local & Cloud Storage:
extension Vibe: SyncTrackable {
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
