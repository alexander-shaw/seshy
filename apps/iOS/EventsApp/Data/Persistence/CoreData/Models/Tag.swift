//
//  Tag.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// MARK: Categorizes PartyEvents and Users.
// Top users (and subscribers) could unlock a feature for creating these.

import Foundation
import CoreData

@objc(Tag)
public class Tag: NSManagedObject {}

extension Tag {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var slug: String  // MARK: Unique and indexed.
    @NSManaged public var categoryRaw: Int16  // TagCategory.
    @NSManaged public var systemDefined: Bool  // Could be user created.
    @NSManaged public var isActive: Bool  // Do not display if not active.

    // Relationships:
    @NSManaged public var events: Set<PartyEvent>

    // Local & Cloud Storage:
    @NSManaged public var lastLocallySavedAt: Date?
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
}

extension Tag {
    public var category: TagCategory {
        get { TagCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
