//
//  UserSettings.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

import Foundation
import CoreData

@objc(UserSettings)
public class UserSettings: NSManagedObject {}

extension UserSettings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }

    @NSManaged public var id: UUID
    @NSManaged public var createdAt: Date

    @NSManaged public var appearanceModeRaw: Int16  // Light or dark mode.
    @NSManaged public var mapStyleRaw: Int16
    @NSManaged public var preferredUnitsRaw: Int16

    // Relationship:
    @NSManaged public var user: DeviceUser

    // Local & Cloud Storage:
    @NSManaged public var lastLocallySavedAt: Date?
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
}

extension UserSettings {
    public var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    public var mapStyle: MapStyle {
        get { MapStyle(rawValue: mapStyleRaw) ?? ((appearanceMode == .darkMode) ? .darkMap : .lightMap)}
        set { mapStyleRaw = newValue.rawValue }
    }

    public var preferredUnits: Units {
        get { Units(rawValue: preferredUnitsRaw) ?? .imperial }
        set { preferredUnitsRaw = newValue.rawValue }
    }

    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
