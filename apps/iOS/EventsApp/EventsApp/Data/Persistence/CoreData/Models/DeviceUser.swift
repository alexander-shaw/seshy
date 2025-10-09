//
//  DeviceUser.swift
//  EventsApp
//
//  Created by Шоу on 10/6/25.
//

import Foundation
import CoreData

@objc(DeviceUser)
public class DeviceUser: NSManagedObject {}

extension DeviceUser {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeviceUser> {
        NSFetchRequest<DeviceUser>(entityName: "DeviceUser")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var createdAt: Date
    @NSManaged public var username: String?

    // Relationships:
    @NSManaged public var login: UserLogin  // One-to-one.
    @NSManaged public var profile: UserProfile  // One-to-one.
    @NSManaged public var settings: UserSettings  // One-to-one.

    // App Features:
    @NSManaged public var memberships: Set<Member>?

    // Local & Cloud Storage:
    @NSManaged public var lastLocallySavedAt: Date?
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
}

extension DeviceUser {
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
