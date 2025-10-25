//
//  Tag.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// This file defines the Core Data entity for tags that categorize UserEvents and Users.
// Tags can be system-defined or user-created and are used for filtering and discovery.
// The model includes category classification and sync capabilities for cloud storage.

// Categorizes UserEvents and Users.
// Top users and subscribers could unlock a feature for creating these.

import Foundation
import CoreData
import CoreDomain

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
    @NSManaged public var systemDefined: Bool  // Can be user-created.
    @NSManaged public var isActive: Bool  // Do not display if not active.

    // Relationships:
    @NSManaged public var events: Set<UserEvent>
}

extension Tag {
    public var category: TagCategory {
        get { TagCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }
}

// Local & Cloud Storage:
extension Tag: SyncTrackable {
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
