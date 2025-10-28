//
//  DeviceFingerprint.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreDomain

@objc(DeviceFingerprint)
public class DeviceFingerprint: NSManagedObject {}

extension DeviceFingerprint {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeviceFingerprint> {
        NSFetchRequest<DeviceFingerprint>(entityName: "DeviceFingerprint")
    }

    @NSManaged public var id: UUID
    
    // Device Identification.
    @NSManaged public var deviceIdentifier: String  // MARK: Unique.
    @NSManaged public var deviceModel: String
    @NSManaged public var systemVersion: String
    @NSManaged public var appVersion: String
    
    // Environment.
    @NSManaged public var regionCode: String
    @NSManaged public var timezone: String
    @NSManaged public var languageCode: String
    
    // Security & Analytics.
    @NSManaged public var lastActiveAt: Date
    @NSManaged public var loginAttemptCount: Int32
    @NSManaged public var isLockedOut: Bool
    @NSManaged public var lockoutUntil: Date?
    
    // Relationships.
    @NSManaged public var deviceUser: DeviceUser?  // Optional relationship to DeviceUser.
}

// Local & Cloud Storage:
extension DeviceFingerprint: SyncTrackable {
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
